namespace IS.LicenseManagement;

enum 72458590 "ISZ License Manager Impl." implements "ISZ ILicense Manager V1"
{
    Extensible = false;

    value(1; V1)
    {
        Caption = 'Version 1';
        Implementation = "ISZ ILicense Manager V1" = "ISZ License Manager V1";
    }
#if DEBUG
    value(2; MockV1)
    {
        Caption = 'Mock Version 1';
        Implementation = "ISZ ILicense Manager V1" = "ISZ License Manager Mock V1";
    }
#endif
}