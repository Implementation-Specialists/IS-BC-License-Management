namespace IS.LicenseManagement;

using System.Telemetry;

codeunit 66006 "ISZ License Manager V1" implements "ISZ ILicense Manager V1"
{
    Access = Internal;

    /// <summary>
    /// Validate license for an extension.
    /// </summary>
    /// <param name="ExtensionId">Extension Id</param>
    /// <returns>True if license is valid; Otherwise false.</returns>
    procedure ValidateLicense(ExtensionId: Guid): Boolean
    var
        LicenseStorageManager: Codeunit "ISZ License Storage Manager";
        LicenseManager: Codeunit "ISZ License Manager";
        ValidateLicenseUrlTok: Label '%1/api/v1/validateLicense/%2/%3', Comment = '%1 = URI scheme and domain, %2 = Tenant Id, %3 = Extension Id', Locked = true;
        License: Text;
        ServiceUrl: Text;
        ValidateLicenseResponse: Text;
    begin
        ServiceUrl := StrSubstNo(ValidateLicenseUrlTok, LicenseStorageManager.GetLicenseServiceUrl(), LicenseManager.GetAadTenantId(), ExtensionId);
        License := LicenseStorageManager.GetLicense(ExtensionId);

        if SendValidateLicenseRequest(ValidateLicenseResponse, ServiceUrl, License) then
            ProcessSuccessResult(ValidateLicenseResponse, ExtensionId)
        else
            ProcessErrorResult(ValidateLicenseResponse);

        exit(LicenseManager.IsLicenseValid(ExtensionId));
    end;

    local procedure ProcessErrorResult(LicenseResponse: Text)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CustomDimensions: Dictionary of [Text, Text];
        ErrorObject: JsonObject;
        ResultObject: JsonObject;
        ErrorCode: JsonToken;
        ErrorMessage: JsonToken;
        ErrorToken: JsonToken;
        ErrorMsg: Label '%1', Comment = '%1 = Error Message';
        ErrorTok: Label 'Code: %1 - Message: %2', Comment = '%1 = Error code, %2 = Error message', Locked = true;
    begin
        if ResultObject.ReadFrom(LicenseResponse) then
            if ResultObject.Get('error', ErrorToken) then begin
                if ErrorToken.IsObject() then
                    ErrorObject := ErrorToken.AsObject();
                // Safely get error code
                if ErrorObject.Get('code', ErrorCode) then;
                // Safely get error message
                if ErrorObject.Get('message', ErrorMessage) then;

                CustomDimensions.Add('ErrorCode', StrSubstNo('%1', ErrorCode));
                CustomDimensions.Add('ErrorMessage', StrSubstNo('%1', ErrorMessage));
                FeatureTelemetry.LogError('ISZ0006', 'IS_LME', 'ProcessLicenseError', StrSubstNo(ErrorTok, ErrorCode, ErrorMessage), '', CustomDimensions);

                Error(ErrorInfo.Create(StrSubstNo(ErrorMsg, ErrorMessage.AsValue().AsText())));
            end;
    end;

    local procedure ProcessSuccessResult(ValidateLicenseResponse: Text; ExtensionId: Guid)
    var
        JsonValidateLicenseObject: JsonObject;
    begin
        if JsonValidateLicenseObject.ReadFrom(ValidateLicenseResponse) then
            UpdateIsolatedStorage(JsonValidateLicenseObject, ExtensionId);
    end;

    local procedure SendValidateLicenseRequest(var JsonResponse: Text; ServiceUrl: Text; License: Text): Boolean
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        LicenseManager: Codeunit "ISZ License Manager";
        ProgressDialog: Dialog;
        HttpClient: HttpClient;
        RequestContent: HttpContent;
        RequestContentHeaders: HttpHeaders;
        RequestHeaders: HttpHeaders;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestBodyTok: Label '{"license": "%1"}', Comment = '%1 = License', Locked = true;
        ValidatingLicenseMsg: Label 'Validating license...';
    begin
        if GuiAllowed() then
            ProgressDialog.Open(ValidatingLicenseMsg);

        RequestContent.GetHeaders(RequestContentHeaders);
        RequestContentHeaders.Clear();
        RequestContentHeaders.Add('Content-Type', 'application/json');
        RequestContent.WriteFrom(StrSubstNo(RequestBodyTok, License));

        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Clear();
        RequestHeaders.Add('User-Agent', LicenseManager.GetAadTenantId());
        RequestHeaders.Add('Connection', 'Keep-Alive');

        RequestMessage.SetRequestUri(ServiceUrl);
        RequestMessage.Method('POST');
        RequestMessage.Content(RequestContent);

        if HttpClient.Send(RequestMessage, ResponseMessage) then begin
            ResponseMessage.Content().ReadAs(JsonResponse);
            if GuiAllowed() then
                ProgressDialog.Close();
            exit(ResponseMessage.IsSuccessStatusCode());
        end else begin
            if GuiAllowed() then
                ProgressDialog.Close();
            FeatureTelemetry.LogError('ISZ0005', 'IS_LME', 'GetServiceLicenseInformation', 'License Service Error');
            ResponseMessage.Content().ReadAs(JsonResponse);
            exit(ResponseMessage.IsSuccessStatusCode());
        end;
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