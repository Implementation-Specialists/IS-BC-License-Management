namespace IS.LicenseManagement;

permissionset 72458590 "ISZ License Mgt."
{
    Assignable = true;
    Caption = 'IS License Management', Locked = true;
    Permissions = tabledata "ISZ Registered Product" = RIMD,
        table "ISZ Registered Product" = X,
        codeunit "ISZ License Storage Manager" = X,
        codeunit "ISZ License Manager" = X,
        codeunit "ISZ License Management Install" = X,
        codeunit "ISZ License Manager Mock V1" = X,
        codeunit "ISZ License Manager V1" = X,
        codeunit "ISZ Telemetry Logger" = X,
        codeunit "ISZ Notification Manager" = X,
        page "ISZ Register Product Dialog" = X,
        page "ISZ Registered Product" = X,
        page "ISZ Registered Products" = X;
}