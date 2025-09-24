namespace IS.LicenseManagementUnitTests;

using IS.LicenseManagement;

codeunit 50100 "ISZ License Mgt. Unit Tests"
{
    // [FEATURE] [License Management]
    Subtype = Test;
    TestPermissions = Restrictive;

    /// <summary>
    /// Tests that a license is expired
    /// </summary>
    [Test]
    [HandlerFunctions('ExpiredRegistrationHandler,SendExpiredNotificationHander')]
    procedure TestRegistrationLicenseIsExpired()
    var
        Assert: Codeunit Assert;
        LicenseManager: Codeunit "ISZ License Manager";
        RegisteredProductsPage: TestPage "ISZ Registered Products";
    begin
        // [SCENARIO] Tests that a license is expired
        Initialize();

        // [GIVEN] Registered Products Page is opened
        OpenRegisteredProductsPage(RegisteredProductsPage);

        // [WHEN] Product Expired license is registered
        RegisteredProductsPage."Promoted Register License".Invoke();

        // [THEN] License is expired
        Assert.IsFalse(LicenseManager.ValidateLicense(GetExtensionId()), 'Registration should be expired.');
    end;

    /// <summary>
    /// Tests that a license is not expired
    /// </summary>
    [Test]
    [HandlerFunctions('ValidRegistrationHandler')]
    procedure TestRegistrationLicenseIsNotExpired()
    var
        Assert: Codeunit Assert;
        LicenseManager: Codeunit "ISZ License Manager";
        RegisteredProductsPage: TestPage "ISZ Registered Products";
    begin
        // [SCENARIO] Tests that a license is not expired
        Initialize();

        // [GIVEN] Registered Products Page is opened
        OpenRegisteredProductsPage(RegisteredProductsPage);

        // [WHEN] Product Valid license is registered
        RegisteredProductsPage."Promoted Register License".Invoke();

        // [THEN] License is not expired
        Assert.IsTrue(LicenseManager.ValidateLicense(GetExtensionId()), 'Registration should not be expired.');
    end;

    /// <summary>
    /// Tests that a valid license is required for validating
    /// </summary>
    [Test]
    [HandlerFunctions('NotValidRegistrationHandler,SendNotValidNotificationHander')]
    procedure TestRegistrationNotValidLicenseErrorMsg()
    var
        Assert: Codeunit Assert;
        LicenseManager: Codeunit "ISZ License Manager";
        RegisteredProductsPage: TestPage "ISZ Registered Products";
    begin
        // [SCENARIO] Tests that a license is required to execute validate
        Initialize();

        // [GIVEN] Registered Products Page is opened
        OpenRegisteredProductsPage(RegisteredProductsPage);

        // [WHEN] Product NotValid license is registered
        RegisteredProductsPage."Promoted Register License".Invoke();

        // [THEN] License is not valid
        Assert.IsFalse(LicenseManager.ValidateLicense(GetExtensionId()), 'Registration should not be valid.');
    end;

    /// <summary>
    /// Tests that a warning is displayed.
    /// </summary>
    [Test]
    [HandlerFunctions('WarningRegistrationHandler,SendWarningNotificationHander')]
    procedure TestWarningMsg()
    var
        Assert: Codeunit Assert;
        LicenseManager: Codeunit "ISZ License Manager";
        RegisteredProductsPage: TestPage "ISZ Registered Products";
    begin
        // [SCENARIO] Tests that a license is required to execute validate
        Initialize();

        // [GIVEN] Registered Products Page is opened
        OpenRegisteredProductsPage(RegisteredProductsPage);

        // [WHEN] Product NotValid license is registered
        RegisteredProductsPage."Promoted Register License".Invoke();

        // [THEN] License is valid
        Assert.IsTrue(LicenseManager.ValidateLicense(GetExtensionId()), 'Registration should be valid.');
    end;

    /// <summary>
    /// Registers 'Expired' license.
    /// </summary>
    /// <param name="RegisterProductDialog">The test page</param>
    [ModalPageHandler]
    procedure ExpiredRegistrationHandler(var RegisterProductDialog: TestPage "ISZ Register Product Dialog")
    begin
        RegisterProductDialog.LicenseControl.SetValue('Expired');
        RegisterProductDialog.OK().Invoke();
    end;

    /// <summary>
    /// Registers 'NoValid' license.
    /// </summary>
    /// <param name="RegisterProductDialog">The test page</param>
    [ModalPageHandler]
    procedure NotValidRegistrationHandler(var RegisterProductDialog: TestPage "ISZ Register Product Dialog")
    begin
        RegisterProductDialog.LicenseControl.SetValue('NotValid');
        RegisterProductDialog.OK().Invoke();
    end;

    /// <summary>
    /// Registers 'Valid' license.
    /// </summary>
    /// <param name="RegisterProductDialog">The test page</param>
    [ModalPageHandler]
    procedure ValidRegistrationHandler(var RegisterProductDialog: TestPage "ISZ Register Product Dialog")
    begin
        RegisterProductDialog.LicenseControl.SetValue('Valid');
        RegisterProductDialog.OK().Invoke();
    end;

    /// <summary>
    /// Registers 'Warning' license.
    /// </summary>
    /// <param name="RegisterProductDialog">The test page</param>
    [ModalPageHandler]
    procedure WarningRegistrationHandler(var RegisterProductDialog: TestPage "ISZ Register Product Dialog")
    begin
        RegisterProductDialog.LicenseControl.SetValue('Warning');
        RegisterProductDialog.OK().Invoke();
    end;

    /// <summary>
    /// Handles expired license Notifications
    /// </summary>
    /// <param name="TheNotification">The notification</param>
    /// <returns></returns>
    [SendNotificationHandler(false)]
    procedure SendExpiredNotificationHander(var TheNotification: Notification): Boolean
    var
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(TheNotification.HasData('ExtensionId'), 'Missing ExtensionId data');
        Assert.AreEqual('Your license for IS License Management Unit Tests is expired. Contact us to purchase a new license.', TheNotification.Message(), 'Incorrect notification message');
    end;

    /// <summary>
    /// Handles not valid license Notifications
    /// </summary>
    /// <param name="TheNotification">The notification</param>
    /// <returns></returns>
    [SendNotificationHandler(false)]
    procedure SendNotValidNotificationHander(var TheNotification: Notification): Boolean
    var
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(TheNotification.HasData('ExtensionId'), 'Missing ExtensionId data');
        Assert.AreEqual('Your license for IS License Management Unit Tests is not valid.', TheNotification.Message(), 'Incorrect notification message');
    end;

    /// <summary>
    /// Handles warning license Notifications
    /// </summary>
    /// <param name="TheNotification">The notification</param>
    /// <returns></returns>
    [SendNotificationHandler(false)]
    procedure SendWarningNotificationHander(var TheNotification: Notification): Boolean
    var
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('Your license for IS License Management Unit Tests expires in 15 days. Contact us to purchase a new license.', TheNotification.Message(), 'Incorrect notification message');
    end;

    local procedure AddLicenseManagementPermission()
    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
    begin
        LibraryLowerPermissions.AddPermissionSet('ISZ License Mgt.');
    end;

    local procedure GetExtensionId(): Guid
    var
        CurrentExtension: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentExtension);
        exit(CurrentExtension.Id());
    end;

    local procedure Initialize()
    var
        LicenseManager: Codeunit "ISZ License Manager";
        CurrentExtension: ModuleInfo;
    begin
        AddLicenseManagementPermission();

        NavApp.GetCurrentModuleInfo(CurrentExtension);
        LicenseManager.RegisterInstalledProduct(CurrentExtension.Id(), CurrentExtension.Name());
    end;

    local procedure OpenRegisteredProductsPage(var RegisteredProductsPage: TestPage "ISZ Registered Products")
    begin
        RegisteredProductsPage.OpenView();
        RegisteredProductsPage.Filter.SetFilter("Extension Id", GetExtensionId());
    end;
}
