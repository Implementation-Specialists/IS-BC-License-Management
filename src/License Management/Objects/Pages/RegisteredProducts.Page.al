namespace IS.LicenseManagement;

page 72458591 "ISZ Registered Products"
{
    ApplicationArea = All;
#if DEBUG
    Caption = 'IS Registered Products (DEBUG)';
#else
    Caption = 'IS Registered Products';
#endif
    CardPageId = "ISZ Registered Product";
    Editable = false;
    Extensible = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "ISZ Registered Product";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Product Name"; Rec."Product Name")
                {
                }
                field("Issued Date"; IssuedDate)
                {
                    Caption = 'Issued Date';
                    ToolTip = 'Specifies the value of the Issued Date field.';
                }
                field("Expiration Date"; ExpirationDate)
                {
                    Caption = 'Expiration Date';
                    ToolTip = 'Specifies the value of the Expiration Date field.';
                }
                field("License Valid"; IsLicenseValid)
                {
                    Caption = 'Valid License';
                    Editable = false;
                    ToolTip = 'Specifies if the product license is valid.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Register License")
            {
                Caption = 'Register License';
                Image = Web;
                ToolTip = 'Executes the Register License action.';

                trigger OnAction()
                var
                    NotificationManager: Codeunit "ISZ Notification Manager";
                    RegisterProductDialog: Page "ISZ Register Product Dialog";
                begin
                    RegisterProductDialog.SetRecord(Rec);
                    if RegisterProductDialog.RunModal() = Action::OK then
                        if not RegisterProductDialog.RegistrationSuccess() then
                            NotificationManager.SendInvalidLicenseNotification(Rec."Extension Id")
                        else
                            NotificationManager.CheckExpirationDateForWarning(Rec."Extension Id");
                end;
            }
#if not RELEASE
            action("Clear Registrations")
            {
                Caption = 'Cleanup';
                Image = ClearLog;
                ToolTip = 'Removes all product registrations.';

                trigger OnAction()
                var
                    RegisteredProduct: Record "ISZ Registered Product";
                    LicenseStorageManager: Codeunit "ISZ License Storage Manager";
                begin
                    if RegisteredProduct.FindSet(false) then
                        repeat
                            LicenseStorageManager.DeleteExtension(RegisteredProduct."Extension Id");
                            RegisteredProduct.Delete(false);
                        until RegisteredProduct.Next() = 0;

                end;
            }
#endif
        }
        area(Promoted)
        {
            actionref("Promoted Register License"; "Register License")
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        LicenseStorageManager: Codeunit "ISZ License Storage Manager";
        LicenseManager: Codeunit "ISZ License Manager";
    begin
        if LicenseStorageManager.GetLicense(Rec."Extension Id") <> '' then begin
            ExpirationDate := LicenseStorageManager.GetExpirationDate(Rec."Extension Id").Date();
            IsLicenseValid := LicenseManager.IsLicenseValid(Rec."Extension Id");
            IssuedDate := LicenseStorageManager.GetIssuedDate(Rec."Extension Id").Date();
        end else begin
            ExpirationDate := 0D;
            IsLicenseValid := false;
            IssuedDate := 0D;
        end;
    end;

    var
        IsLicenseValid: Boolean;
        ExpirationDate: Date;
        IssuedDate: Date;
}