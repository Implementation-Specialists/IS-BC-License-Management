namespace IS.LicenseManagement;

page 66002 "ISZ Register Product Dialog"
{
    ApplicationArea = All;
    Caption = 'Register Product';
    Extensible = false;
    PageType = StandardDialog;
    SourceTable = "ISZ Registered Product";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Register Product';

                field("Product Name"; Rec."Product Name")
                {
                    Editable = false;
                }
                field(LicenseControl; License)
                {
                    Caption = 'License';
                    ShowMandatory = true;
                    ToolTip = 'Specifies the value of the license field.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        LicenseStorageManager: Codeunit "ISZ License Storage Manager";
    begin
        License := LicenseStorageManager.GetLicense(Rec."Extension Id");
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        LicenseManager: Codeunit "ISZ License Manager";
        ErrorMsg: Label 'You must specify a license to continue.';
    begin
        if CloseAction = Action::OK then
            if License = '' then
                Error(ErrorMsg)
            else
                RegisterResult := LicenseManager.RegisterProductLicense(Rec."Extension Id", License);
    end;

    var
        RegisterResult: Boolean;
        License: Text;

    /// <summary>
    /// Gets the license registration result.
    /// </summary>
    /// <returns>True when registration was successful; Otherwise false.</returns>
    procedure RegistrationSuccess(): Boolean
    begin
        exit(RegisterResult);
    end;
}