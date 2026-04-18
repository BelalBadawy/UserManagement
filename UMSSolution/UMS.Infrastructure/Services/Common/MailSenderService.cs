using UMS.Application.Dtos.Email;
using FluentEmail.Core;
using FluentEmail.Smtp;
using Microsoft.Extensions.Options;
using System.Net;
using System.Net.Mail;
using UMS.Application.Interfaces.Common;

namespace UMS.Infrastructure.Services.Common
{
    public class MailSenderService : IEmailService
    {
        #region Fields

        private readonly EmailConfiguration _emailSettings;

        #endregion

        public MailSenderService(IOptions<EmailConfiguration> emailConfig)
        {
            _emailSettings = emailConfig.Value;
        }

        public async Task<string> SendAsync(SendEmailDto request, CancellationToken ct)
        {
            try
            {
                // 1) Configure SMTP sender inside SendAsync
                var smtpClient = new SmtpClient(_emailSettings.Host, _emailSettings.Port)
                {
                    Credentials = new NetworkCredential(_emailSettings.Email, _emailSettings.Password),
                    EnableSsl = true
                };
                Email.DefaultSender = new SmtpSender(smtpClient);

                // 2) Create email
                var email = Email
                    .From(_emailSettings.Email, _emailSettings.DisplayName)
                    .Subject(request.Subject)
                    .Body(request.MessageBody, isHtml: true);

                // 3) To recipients
                if (request.ToEmails?.Any() == true)
                    foreach (var to in request.ToEmails)
                        email.To(to);
                else if (!string.IsNullOrEmpty(request.MailTo))
                    email.To(request.MailTo);

                // 4) CC
                if (request.EmailCC?.Any() == true)
                    foreach (var cc in request.EmailCC)
                        email.CC(cc);

                // 5) BCC
                if (request.EmailBCC?.Any() == true)
                    foreach (var bcc in request.EmailBCC)
                        email.BCC(bcc);

                // 6) Attachments
                if (request.Attachments?.Any() == true)
                {
                    var attachmentList = new List<FluentEmail.Core.Models.Attachment>();
                    foreach (var file in request.Attachments)
                    {
                        if (file.Length > 0)
                        {
                            using var ms = new MemoryStream();
                            await file.CopyToAsync(ms);
                            ms.Position = 0;

                            attachmentList.Add(new FluentEmail.Core.Models.Attachment
                            {
                                Data = ms,                  // byte[]
                                Filename = file.FileName,             // file name
                                ContentType = file.ContentType        // MIME type string
                            });
                        }
                    }

                    if (attachmentList.Any())
                        email.Attach(attachmentList);
                }

                // 7) Send email
                var response = await email.SendAsync(ct);

                return response.Successful
                    ? string.Empty
                    : string.Join("; ", response.ErrorMessages);
            }
            catch (Exception ex)
            {
                return ex.Message;
            }
        }
    }
}
