namespace IS.LicenseManagement;

codeunit 72458591 "ISZ License Management Install"
{
    Access = Internal;
    Permissions = tabledata "ISZ Registered Product" = r;
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        IsolatedStorageManager: Codeunit "ISZ License Storage Manager";
    begin
#if DEBUG
        IsolatedStorageManager.AddImplementation(Enum::"ISZ License Manager Impl."::MockV1);
#else
        IsolatedStorageManager.AddImplementation(Enum::"ISZ License Manager Impl."::V1);
#endif

#if LOCALSERVICE
        IsolatedStorageManager.AddLicenseServiceUrl('http://192.168.50.8:7080');
#elif DEV
        IsolatedStorageManager.AddLicenseServiceUrl(StrSubstNo(ServiceUrlFormatTok, 'dev'));
#elif UAT
        IsolatedStorageManager.AddLicenseServiceUrl('StrSubstNo(ServiceUrlFormatTok, 'tie'));
#else
        IsolatedStorageManager.AddLicenseServiceUrl(StrSubstNo(ServiceUrlFormatTok, 'prod'));
#endif
    end;

#if not LOCALSERVICE
    var
        ServiceUrlFormatTok: Label 'https://is-licensing-%1-svc.azurewebsites.net', Comment = '%1 = Environment', Locked = true;
#endif
}