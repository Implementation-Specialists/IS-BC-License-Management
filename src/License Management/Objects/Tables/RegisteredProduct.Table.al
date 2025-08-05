namespace IS.LicenseManagement;

table 72458590 "ISZ Registered Product"
{
    Caption = 'Implementation Specialists Registered Product';
    DataCaptionFields = "Product Name";
    DataClassification = CustomerContent;
    DataPerCompany = false;
    DrillDownPageId = "ISZ Registered Product";
    Extensible = false;
    LookupPageId = "ISZ Registered Product";

    fields
    {
        field(1; "Extension Id"; Guid)
        {
            AllowInCustomizations = Never;
            Caption = 'Extension Id';
            Editable = false;
            NotBlank = true;
            ToolTip = 'Specifies the value of the Extension Id field.';
        }
        field(2; "Product Name"; Text[250])
        {
            AllowInCustomizations = Never;
            Caption = 'Product Name';
            Editable = false;
            ToolTip = 'Specifies the value of the Product Name field.';
        }
    }
    keys
    {
        key(PK; "Extension Id")
        {
            Clustered = true;
        }
    }
    fieldgroups
    {
        fieldgroup(DropDown; "Product Name", "Extension Id")
        {
        }
        fieldgroup(Brick; "Product Name", "Extension Id")
        {
        }
    }
}