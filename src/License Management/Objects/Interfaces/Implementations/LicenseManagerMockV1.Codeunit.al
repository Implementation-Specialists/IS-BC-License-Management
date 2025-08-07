namespace IS.LicenseManagement;

codeunit 66005 "ISZ License Manager Mock V1" implements "ISZ ILicense Manager V1"
{
    Access = Internal;

    /// <summary>
    /// Validate license for an extension.
    /// </summary>
    /// <param name="ExtensionId">Extension Id</param>
    /// <returns>True if license is valid; Otherwise false.</returns>
    procedure ValidateLicense(ExtensionId: Guid): Boolean
    var
        LicenseManager: Codeunit "ISZ License Manager";
        LicenseStorageManager: Codeunit "ISZ License Storage Manager";
        LicenseResponse: Text;
    begin
        if GetServiceLicenseInformation(LicenseResponse, LicenseStorageManager.GetLicense(ExtensionId)) then
            ProcessLicenseResult(LicenseResponse, ExtensionId);

        exit(LicenseManager.IsLicenseValid(ExtensionId));
    end;

    local procedure CreateDebugJsonResponse(ExpirationDate: Date): Text
    var
        JsonLicenseObject: JsonObject;
        JsonLicenseInfoObject: JsonObject;
    begin
        if ExpirationDate = 0D then
            JsonLicenseObject.Add('expirationDate', CreateDateTime(0D, 0T))
        else
            JsonLicenseInfoObject.Add('expirationDate', CreateDateTime(ExpirationDate, Time()));

        JsonLicenseInfoObject.Add('issueDate', CurrentDateTime());

        JsonLicenseObject.Add('license', JsonLicenseInfoObject);

        exit(Format(JsonLicenseObject));
    end;

    local procedure GetServiceLicenseInformation(var JsonResponse: Text; License: Text): Boolean
    begin
        case true of
            License.StartsWith('Valid'):
                JsonResponse := CreateDebugJsonResponse(Today() + 60);
            License.StartsWith('Expired'):
                JsonResponse := CreateDebugJsonResponse(Today() - 1);
            License.StartsWith('Warning'):
                JsonResponse := CreateDebugJsonResponse(Today() + 15);
            else
                JsonResponse := CreateDebugJsonResponse(0D);
        end;

        exit(true);
    end;

    local procedure ProcessLicenseResult(LicenseResponse: Text; ExtensionId: Guid)
    var
        JsonLicenseResult: JsonObject;
    begin
        if JsonLicenseResult.ReadFrom(LicenseResponse) then
            UpdateIsolatedStorage(JsonLicenseResult, ExtensionId);
    end;

    local procedure UpdateIsolatedStorage(JsonValidateLicenseObject: JsonObject; ExtensionId: Guid)
    var
        LicenseStorageManager: Codeunit "ISZ License Storage Manager";
        LicenseObject: JsonObject;
        ExpirationDateTime: JsonToken;
        IssueDateTime: JsonToken;
    begin
        LicenseObject := JsonValidateLicenseObject.GetObject('license');

        if LicenseObject.Get('expirationDate', ExpirationDateTime) then
            LicenseStorageManager.AddExpirationDate(ExtensionId, ExpirationDateTime.AsValue().AsDateTime());

        if LicenseObject.Get('issueDate', IssueDateTime) then
            LicenseStorageManager.AddIssuedDate(ExtensionId, IssueDateTime.AsValue().AsDateTime());
    end;
}