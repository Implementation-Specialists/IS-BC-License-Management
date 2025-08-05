namespace IS.LicenseManagement;

using System.Environment.Configuration;
using System.Telemetry;

codeunit 72458593 "ISZ Notification Manager"
{
    Permissions = tabledata "ISZ Registered Product" = r;

    /// <summary>
    /// Checks expiration date and sends warning if license expires soon.
    /// </summary>
    /// <param name="ExtensionId">The id of the extension</param>
    internal procedure CheckExpirationDateForWarning(ExtensionId: Guid)
    var
        LicenseStorageManager: Codeunit "ISZ License Storage Manager";
        ExpirationDate: DateTime;
        ExpiryDuration: Duration;
        ExpiryDays: Integer;
    begin
        ExpirationDate := LicenseStorageManager.GetExpirationDate(ExtensionId);

        if (ExpirationDate <> 0DT) and (ExpirationDate >= LicenseStorageManager.ConvertDateTimeToUTC(CurrentDateTime())) then begin
            ExpiryDuration := ExpirationDate - LicenseStorageManager.ConvertDateTimeToUTC(CurrentDateTime());
            ExpiryDays := Round(ExpiryDuration / 86400000, 1, '>');
            if ExpiryDays <= 30 then
                SendExpirationWarningNotification(ExtensionId, ExpiryDays);
        end;
    end;

    /// <summary>
    /// Opens the contact us link from a Notification.
    /// </summary>
    /// <param name="InvalidLicenseNotification">A Notification to open the contact us link</param>
    internal procedure Notification_ContactUs(InvalidLicenseNotification: Notification)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('ISZ0004', 'IS_LME', "Feature Uptake Status"::Discovered);

        Hyperlink('https://www.iscorp.biz/contact-us/');
    end;

    /// <summary>
    /// Disables the license warning notification.
    /// </summary>
    /// <param name="WarningNotification">A license warning Notification</param>
    internal procedure Notification_DontShow(WarningNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.Disable(WarningNotification.Id());
    end;

    /// <summary>
    /// Opens the Registered License Dialog from a Notification.
    /// </summary>
    /// <param name="InvalidLicenseNotification">A Notification with the ExtensionId data set</param>
    internal procedure Notification_OpenProductRegistrationDialog(InvalidLicenseNotification: Notification)
    var
        RegisteredProduct: Record "ISZ Registered Product";
        RegisterProductDialog: Page "ISZ Register Product Dialog";
        ExtensionId: Guid;
        ErrorMsg: Label 'Unable to find product with id: %1', Comment = '%1 = Extension Id';
    begin
        Evaluate(ExtensionId, InvalidLicenseNotification.GetData('ExtensionId'));
        if RegisteredProduct.Get(ExtensionId) then begin
            RegisterProductDialog.SetRecord(RegisteredProduct);
            if RegisterProductDialog.RunModal() = Action::OK then
                if not RegisterProductDialog.RegistrationSuccess() then
                    SendInvalidLicenseNotification(RegisteredProduct."Extension Id")
                else
                    SendValidLicenseNotification(RegisteredProduct."Extension Id");

            CheckExpirationDateForWarning(RegisteredProduct."Extension Id");
        end else
            Error(ErrorMsg, ExtensionId);
    end;

    /// <summary>
    /// Sends a notification that a license is not valid with actions to register and a contact us link.
    /// </summary>
    /// <param name="ExtensionId">The id of the extension</param>
    internal procedure SendInvalidLicenseNotification(ExtensionId: Guid)
    var
        RegisteredProduct: Record "ISZ Registered Product";
        LicenseStorageManager: Codeunit "ISZ License Storage Manager";
        LicenseManager: Codeunit "ISZ License Manager";
        InvalidLicenseNotification: Notification;
        ExpiredLicenseMsg: Label 'Your license for %1 is expired. Contact us to purchase a new license.', Comment = '%1 = Product Name';
        InvalidLicenseMsg: Label 'Your license for %1 is not valid.', Comment = '%1 = Product Name';
        InvalidLicenseNotifcationIdTok: Label '2900a0ca-4226-4d66-81f7-f124a8a51ef6', Locked = true;
    begin
        if RegisteredProduct.Get(ExtensionId) then begin
            InvalidLicenseNotification.Id(InvalidLicenseNotifcationIdTok);

            AddContactUsAndRegisterNowNotificationActions(InvalidLicenseNotification, ExtensionId);

            if (LicenseStorageManager.GetExpirationDate(ExtensionId).Date() = 0D)
                or (LicenseStorageManager.GetLicense(ExtensionId) = '') then
                InvalidLicenseNotification.Message(StrSubstNo(InvalidLicenseMsg, RegisteredProduct."Product Name"))
            else
                if not LicenseManager.IsLicenseValid(ExtensionId) then
                    InvalidLicenseNotification.Message(StrSubstNo(ExpiredLicenseMsg, RegisteredProduct."Product Name"));

            InvalidLicenseNotification.Scope := NotificationScope::LocalScope;
            InvalidLicenseNotification.Send();
        end;
    end;

    local procedure AddContactUsAndRegisterNowNotificationActions(var InvalidLicenseNotification: Notification; ExtensionId: Guid)
    var
        InvalidLicenseContactUsMsg: Label 'Contact Us';
        InvalidLicenseRegisterMsg: Label 'Register now';
    begin
        InvalidLicenseNotification.AddAction(InvalidLicenseRegisterMsg, Codeunit::"ISZ Notification Manager", 'Notification_OpenProductRegistrationDialog');
        InvalidLicenseNotification.AddAction(InvalidLicenseContactUsMsg, Codeunit::"ISZ Notification Manager", 'Notification_ContactUs');
        InvalidLicenseNotification.SetData('ExtensionId', ExtensionId);
    end;

    local procedure InsertWarningNotificationToMyNotifications(ExtensionId: Guid)
    var
        RegisteredProduct: Record "ISZ Registered Product";
        MyNotifications: Record "My Notifications";
        WarningNotificationDescriptionLbl: Label 'Show a warning that the %1 license is expiring soon.', Comment = '%1 = Product Name';
        WarningNotificationNameLbl: Label 'Show %1 license expiration warning', Comment = '%1 = Product Name';
    begin
        if not MyNotifications.Get(UserId(), ExtensionId) then
            if RegisteredProduct.Get(ExtensionId) then
                MyNotifications.InsertDefault(ExtensionId,
                    StrSubstNo(WarningNotificationNameLbl,
                        RegisteredProduct."Product Name"),
                        StrSubstNo(WarningNotificationDescriptionLbl,
                        RegisteredProduct."Product Name"),
                        true);
    end;

    local procedure SendExpirationWarningNotification(ExtensionId: Guid; ExpiryDays: Integer)
    var
        RegisteredProduct: Record "ISZ Registered Product";
        MyNotifications: Record "My Notifications";
        WarningExpirationNotification: Notification;
        PluralTxt: Text[1];
        DontShowMsg: Label 'Don''t show again';
        WarningExpirationMsg: Label 'Your license for %1 expires in %2 day%3. Contact us to purchase a new license.', Comment = '%1 = Product Name, %2 = Expiry days %3 = s when greater than 1 day';
    begin
        if RegisteredProduct.Get(ExtensionId) then begin
            InsertWarningNotificationToMyNotifications(ExtensionId);

            if MyNotifications.IsEnabled(ExtensionId) then begin
                if ExpiryDays > 1 then
                    PluralTxt := 's';

                WarningExpirationNotification.Id(ExtensionId);
                AddContactUsAndRegisterNowNotificationActions(WarningExpirationNotification, ExtensionId);
                WarningExpirationNotification.AddAction(DontShowMsg, Codeunit::"ISZ Notification Manager", 'Notification_DontShow');
                WarningExpirationNotification.Message(StrSubstNo(WarningExpirationMsg, RegisteredProduct."Product Name", ExpiryDays, PluralTxt));
                WarningExpirationNotification.Scope := NotificationScope::LocalScope;
                WarningExpirationNotification.Send();
            end;
        end;
    end;

    local procedure SendValidLicenseNotification(ExtensionId: Guid)
    var
        RegisteredProduct: Record "ISZ Registered Product";
        ValidLicenseNotification: Notification;
        ValidLicenseMsg: Label 'Your license for %1 is now valid. Close and reopen the current page to continue.', Comment = '%1 = Product Name';
        ValidLicenseNotifcationIdTok: Label 'b1cb2979-c4ef-4bc1-b96a-cc856a27ef4b', Locked = true;
    begin
        if RegisteredProduct.Get(ExtensionId) then begin
            ValidLicenseNotification.Id(ValidLicenseNotifcationIdTok);
            ValidLicenseNotification.Message(StrSubstNo(ValidLicenseMsg, RegisteredProduct."Product Name"));
            ValidLicenseNotification.Scope := NotificationScope::LocalScope;
            ValidLicenseNotification.Send();
        end;
    end;
}