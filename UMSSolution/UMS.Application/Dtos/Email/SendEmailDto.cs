using Microsoft.AspNetCore.Http;

namespace UMS.Application.Dtos.Email
{
    /// <summary>
    /// DTO for sending emails. Contains recipient addresses, subject, body,
    /// attachments and optional CC/BCC lists.
    /// </summary>
    public class SendEmailDto
    {
        /// <summary>
        /// Primary recipient email address.
        /// </summary>
        public string MailTo { get; set; } = string.Empty;

        /// <summary>
        /// Email subject.
        /// </summary>
        public string Subject { get; set; } = string.Empty;

        /// <summary>
        /// Body/content of the email message.
        /// </summary>
        public string MessageBody { get; set; } = string.Empty;

        /// <summary>
        /// Optional file attachments.
        /// </summary>
        public IList<IFormFile> Attachments { get; set; } = new List<IFormFile>();

        /// <summary>
        /// Additional recipient addresses.
        /// </summary>
        public IEnumerable<string> ToEmails { get; set; } = new List<string>();

        /// <summary>
        /// CC addresses for the email.
        /// </summary>
        public IEnumerable<string> EmailCC { get; set; } = new List<string>();

        /// <summary>
        /// BCC addresses for the email.
        /// </summary>
        public IEnumerable<string> EmailBCC { get; set; } = new List<string>();

        /// <summary>
        /// Email priority (e.g. Normal, High).
        /// </summary>
        public string Priority { get; set; } = string.Empty;

    }
}
