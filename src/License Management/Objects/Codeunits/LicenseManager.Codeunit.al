namespace IS.LicenseManagement;

using System.Telemetry;
using System.Environment;
using System.Azure.Identity;

codeunit 72458591 "ISZ License Manager"
{
    Permissions = tabledata "ISZ Registered Product" = Rim;

    var
        ISTenantIdTxt: Label 'c5fa7775-553d-4d2b-a8e9-fa549ea4b164', Locked = true;

    /// <summary>
    /// Registers an Implementation Specialists product when installed.
    /// </summary>
    /// <param name="ExtensionId">The id of the extension</param>
    /// <param name="ProductName">The name of the product</param>
    procedure RegisterInstalledProduct(ExtensionId: Guid; ProductName: Text)
    var
        RegisteredProduct: Record "ISZ Registered Product";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('ISZ0001', 'IS_LME', "Feature Uptake Status"::Used);

        if not RegisteredProduct.Get(ExtensionId) then begin
            RegisteredProduct.Init();

            RegisteredProduct."Extension Id" := ExtensionId;
            RegisteredProduct."Product Name" := CopyStr(ProductName, 1, MaxStrLen(RegisteredProduct."Product Name"));
            RegisteredProduct.Insert(false);
        end else
            if RegisteredProduct."Product Name" <> ProductName then begin
                RegisteredProduct."Product Name" := CopyStr(ProductName, 1, MaxStrLen(RegisteredProduct."Product Name"));
                RegisteredProduct.Modify(false);
            end;
    end;

#pragma warning disable LC0052
#if LOCALSERVICE or DEV
    internal procedure GetAadTenantId(): Text
    begin
        // IS Tenant ID
        exit(ISTenantIdTxt);
    end;
#else
    internal procedure GetAadTenantId(): Text
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if (EnvironmentInformation.IsSaaS()) then
            exit(AzureADTenant.GetAadTenantId())
        else
            exit(ISTenantIdTxt);
    end;
#endif
#pragma warning restore LC0052

    /// <summary>
    /// Registers a license and then validates the license.
    /// </summary>
    /// <param name="ExtensionId">The id of the extension</param>
    /// <param name="License">The license</param>
    /// <returns>True if license is valid; Otherwise false.</returns>
    internal procedure RegisterProductLicense(ExtensionId: Guid; License: Text): Boolean
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        LicenseStorageManager: Codeunit "ISZ License Storage Manager";
    begin
        if LicenseStorageManager.AddLicense(ExtensionId, License) then begin
            FeatureTelemetry.LogUptake('ISZ0002', 'IS_LME', "Feature Uptake Status"::Used);
            exit(ValidateLicense(ExtensionId));
        end;
    end;

    /// <summary>
    /// Checks if license is valid and displays a Notification when not valid.
    /// This is the entry point from extensions using the LME.
    /// </summary>
    /// <param name="ExtensionId">The id of the extension</param>
    /// <returns>True if license is valid; Otherwise false.</returns>
    procedure ValidateLicense(ExtensionId: Guid): Boolean
    begin
        exit(ValidateLicenseWithNotifications(ExtensionId));
    end;

    /// <summary>
    /// Checks if a license is expired.
    /// </summary>
    /// <param name="ExtensionId">The id of the extension</param>
    /// <returns>True if license is valid; Otherwise false.</returns>
    internal procedure IsLicenseValid(ExtensionId: Guid): Boolean
    var
        LicenseStorageManager: Codeunit "ISZ License Storage Manager";
    begin
        exit((LicenseStorageManager.GetExpirationDate(ExtensionId) >= LicenseStorageManager.ConvertDateTimeToUTC(CurrentDateTime())));
    end;

    local procedure ValidateLicenseWithNotifications(ExtensionId: Guid): Boolean
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        LicenseStorageManager: Codeunit "ISZ License Storage Manager";
        NotificationManager: Codeunit "ISZ Notification Manager";
        Implementation: Interface "ISZ ILicense Manager V1";
    begin
        if LicenseStorageManager.GetLicense(ExtensionId) = '' then begin
            NotificationManager.SendInvalidLicenseNotification(ExtensionId);
            exit(false);
        end;

        if (IsLicenseValid(ExtensionId)) then begin
            NotificationManager.CheckExpirationDateForWarning(ExtensionId);
            exit(true);
        end;

        Implementation := LicenseStorageManager.GetImplementation();

        if not Implementation.ValidateLicense(ExtensionId) then begin
            FeatureTelemetry.LogError('ISZ0003', 'IS_LME', 'ValidateLicense', 'Invalid License');
            NotificationManager.SendInvalidLicenseNotification(ExtensionId)
        end else begin
            NotificationManager.CheckExpirationDateForWarning(ExtensionId);
            exit(true);
        end;
    end;
}