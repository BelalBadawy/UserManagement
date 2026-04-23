using AutoFixture;
using Bogus;
using UMS.Application.Features.Token.Queries;
using UMS.Application.Features.Users.Commands;
using UMS.Application.Features.Users.Models.Responses;

namespace UMS.Application.Tests.Fixtures;

internal static class TestData
{
    private static readonly Fixture Fixture = new();
    private static readonly Faker Faker = new();

    public static UserRegistrationRequest UserRegistrationRequest() => new()
    {
        FullName = Faker.Name.FullName(),
        Email = Faker.Internet.Email(),
        Password = "Valid@123",
        ConfirmPassword = "Valid@123",
        PhoneNumber = "01012345678",
        AutoConfirmEmail = true,
        ActivateUser = true
    };

    public static TokenRequest TokenRequest() => new()
    {
        Email = Faker.Internet.Email(),
        Password = "Valid@123"
    };

    public static UserResponse UserResponse(int? id = null) => new()
    {
        Id = id ?? Fixture.Create<int>(),
        FullName = Faker.Name.FullName(),
        Email = Faker.Internet.Email(),
        UserName = Faker.Internet.UserName(),
        IsActive = true,
        PhoneNumber = "01012345678"
    };
}
