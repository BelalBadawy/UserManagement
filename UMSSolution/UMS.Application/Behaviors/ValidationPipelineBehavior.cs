namespace UMS.Application.Behaviors
{
    internal class ValidationPipelineBehavior<TRequest, TResponse>
        : IPipelineBehavior<TRequest, TResponse>
        where TRequest : IRequest<TResponse>, IValidateMe
    {
        private readonly IEnumerable<IValidator<TRequest>> _validators;

        public ValidationPipelineBehavior(IEnumerable<IValidator<TRequest>> validators)
        {
            _validators = validators;
        }

        public async ValueTask<TResponse> Handle(
            TRequest request,
            MessageHandlerDelegate<TRequest, TResponse> next,
            CancellationToken cancellationToken)
        {
            if (_validators.Any())
            {
                var context = new ValidationContext<TRequest>(request);
                var validationResults = await Task
                    .WhenAll(_validators.Select(vr => vr.ValidateAsync(context, cancellationToken)));

                var failures = validationResults.SelectMany(vr => vr.Errors)
                    .Where(f => f != null)
                    .ToList();

                if (failures.Count > 0)
                {
                    var errorMessages = new List<string>();

                    foreach (var failure in failures)
                    {
                        errorMessages.Add(failure.ErrorMessage);
                    }

                    return CreateValidationFailureResponse(errorMessages);
                }
            }

            return await next(request, cancellationToken);
        }

        private static TResponse CreateValidationFailureResponse(IReadOnlyList<string> errorMessages)
        {
            if (typeof(TResponse).IsGenericType &&
                typeof(TResponse).GetGenericTypeDefinition() == typeof(IResponseWrapper<>))
            {
                var dataType = typeof(TResponse).GetGenericArguments()[0];
                var wrapperType = typeof(ResponseWrapper<>).MakeGenericType(dataType);
                var failMethod = wrapperType.GetMethod(
                    nameof(ResponseWrapper<object>.Fail),
                    [typeof(IReadOnlyList<string>), typeof(int)]);

                return (TResponse)failMethod!.Invoke(null, [errorMessages, 500])!;
            }

            return (TResponse)ResponseWrapper.Fail(errorMessages);
        }
    }
}
