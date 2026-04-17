namespace UMS.Domain.Enums;

/// <summary>
/// Supported Multi-Factor Authentication methods.
/// </summary>
public enum MfaMethod
{
    None = 0,
    Email = 1,
    Totp = 2,
    Sms = 3
}

/// <summary>
/// Results of an authentication attempt.
/// </summary>
public enum AuthResult
{
    Success = 1,
    Failure = 2,
    MfaRequired = 3,
    LockedOut = 4,
    NotAllowed = 5
}

/// <summary>
/// Status of a refresh token family lineage.
/// </summary>
public enum TokenFamilyStatus
{
    Active = 1,
    RevokedByReuse = 2,
    LoggedOut = 3,
    Expired = 4
}
