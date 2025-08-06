namespace IS.LicenseManagementUnitTests;

permissionset 50101 TestExtAccess
{
    Assignable = true;
    Caption = 'Test Extension Access', MaxLength = 30;
    Permissions =
        codeunit "ISZ License Mgt. Unit Tests" = X;
}