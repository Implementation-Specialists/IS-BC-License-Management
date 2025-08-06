namespace IS.LicenseManagement;

codeunit 72458590 "ISZ License Storage Manager"
{
    var
        ExpirationDateFormatTok: Label '%1_ExpirationDate', Comment = '%1 = Extension Id', Locked = true;
        ImplementationTok: Label 'Implementation', Locked = true;
        IssueDateFormatTok: Label '%1_IssueDate', Comment = '%1 = Extension Id', Locked = true;
        LicenseKeyFormatTok: Label '%1_LicenseKey', Comment = '%1 = Extension Id', Locked = true;
        ServiceUrlTok: Label 'LicenseServiceUrl', Locked = true;

    /// <summary>
    /// Adds expiration date for extension to isolated storage.
    /// </summary>
    /// <param name="ExtensionId">The id of the extension</param>
    /// <param name="ExpirationDate">The expiration date to add</param>
    /// <returns>True if successfully added; Otherwise false.</returns>
    internal procedure AddExpirationDate(ExtensionId: Guid; ExpirationDate: DateTime): Boolean
    begin
        exit(IsolatedStorage.Set(StrSubstNo(ExpirationDateFormatTok, ExtensionId), Format(ConvertDateTimeToUTC(ExpirationDate)), DataScope::Module));
    end;

    /// <summary>
    /// Adds implementation to use to isolated storage.
    /// </summary>
    /// <param name="LicenseMgtImplementation">The implementation to use</param>
    /// <returns>True if successfully added; Otherwise false.</returns>
    internal procedure AddImplementation(LicenseMgtImplementation: Enum "ISZ License Manager Impl."): Boolean
    begin
        exit(IsolatedStorage.Set(ImplementationTok, Format(LicenseMgtImplementation.AsInteger()), DataScope::Module));
    end;

    /// <summary>
    /// Adds issued date for extension to isolated storage.
    /// </summary>
    /// <param name="ExtensionId">The id of the extension</param>
    /// <param name="IssuedDate">The expiration date to add</param>
    /// <returns>True if successfully added; Otherwise false.</returns>
    internal procedure AddIssuedDate(ExtensionId: Guid; IssuedDate: DateTime): Boolean
    begin
        exit(IsolatedStorage.Set(StrSubstNo(IssueDateFormatTok, ExtensionId), Format(ConvertDateTimeToUTC(IssuedDate)), DataScope::Module));
    end;

    /// <summary>
    /// Adds the license service url to isolated storage.
    /// </summary>
    /// <param name="ServiceUrl">The license service url</param>
    /// <returns>True if successfully added; Otherwise false.</returns>
    internal procedure AddLicenseServiceUrl(ServiceUrl: Text): Boolean
    begin
        exit(IsolatedStorage.Set(ServiceUrlTok, ServiceUrl, DataScope::Module));
    end;

    /// <summary>
    /// Resets expiration dates in isolated storage and adds license for extension to isolated storage.
    /// </summary>
    /// <param name="ExtensionId">The id of the extension</param>
    /// <param name="LicenseKey">The license to add</param>
    /// <returns>True if successfully added; Otherwise false.</returns>
    internal procedure AddLicense(ExtensionId: Guid; LicenseKey: Text): Boolean
    begin
        if GetLicense(ExtensionId) <> LicenseKey then
            ClearLicenseDates(ExtensionId);

        exit(IsolatedStorage.Set(StrSubstNo(LicenseKeyFormatTok, ExtensionId), LicenseKey, DataScope::Module));
    end;

#if not RELEASE
    /// <summary>
    /// Deletes all isolated storage values for an extension.
    /// </summary>
    /// <param name="ExtensionId"></param>
    internal procedure DeleteExtension(ExtensionId: Guid)
    begin
        // Safetly delete
        if IsolatedStorage.Delete(StrSubstNo(ExpirationDateFormatTok, ExtensionId), DataScope::Module) then;
        // Safetly delete
        if IsolatedStorage.Delete(StrSubstNo(IssueDateFormatTok, ExtensionId), DataScope::Module) then;
        // Safetly delete
        if IsolatedStorage.Delete(StrSubstNo(LicenseKeyFormatTok, ExtensionId), DataScope::Module) then;
    end;
#endif

    /// <summary>
    /// Removes license expiration dates for an extension from isolated storage invalidating a license.
    /// </summary>
    /// <param name="ExtensionId">The id of the extension</param>
    internal procedure ClearLicenseDates(ExtensionId: Guid)
    begin
        if IsolatedStorage.Contains(StrSubstNo(ExpirationDateFormatTok, ExtensionId), DataScope::Module) then
            IsolatedStorage.Delete(StrSubstNo(ExpirationDateFormatTok, ExtensionId), DataScope::Module);

        if IsolatedStorage.Contains(StrSubstNo(IssueDateFormatTok, ExtensionId), DataScope::Module) then
            IsolatedStorage.Delete(StrSubstNo(IssueDateFormatTok, ExtensionId), DataScope::Module);
    end;

    /// <summary>
    /// Converts a datetime to UTC datetime value.
    /// </summary>
    /// <param name="ConvertDateTime"></param>
    /// <returns>The UTC datetime value.</returns>
    internal procedure ConvertDateTimeToUTC(ConvertDateTime: DateTime) UTCDateTime: DateTime
    begin
        Evaluate(UTCDateTime, Format(ConvertDateTime, 0, 9));
    end;

    /// <summary>
    /// Gets the expiration date for extension from isolated storage.
    /// </summary>
    /// <param name="ExtensionId">The id of the extension</param>
    /// <returns>The expiration date</returns>
    internal procedure GetExpirationDate(ExtensionId: Guid) ExpirationDate: DateTime
    var
        CurrentValue: Text;
    begin
        if IsolatedStorage.Contains(StrSubstNo(ExpirationDateFormatTok, ExtensionId), DataScope::Module) then
            if IsolatedStorage.Get(StrSubstNo(ExpirationDateFormatTok, ExtensionId), DataScope::Module, CurrentValue) then
                Evaluate(ExpirationDate, CurrentValue);
    end;

    /// <summary>
    /// Gets the current license management from isolated storage.
    /// </summary>
    /// <returns>The license management implementation</returns>
    internal procedure GetImplementation() Implementation: Interface "ISZ ILicense Manager V1"
    var
        CurrentValue: Integer;
        CurrentImplementation: Text;
    begin
        if IsolatedStorage.Contains(ImplementationTok, DataScope::Module) then
            if IsolatedStorage.Get(ImplementationTok, DataScope::Module, CurrentImplementation) then begin
                Evaluate(CurrentValue, CurrentImplementation);
                exit(Enum::"ISZ License Manager Impl.".FromInteger(CurrentValue));
            end;

        exit(Enum::"ISZ License Manager Impl."::V1);
    end;

    /// <summary>
    /// Gets the issued date for extension from isolated storage.
    /// </summary>
    /// <param name="ExtensionId">The id of the extension</param>
    /// <returns>The date of the soft expiration.</returns>
    internal procedure GetIssuedDate(ExtensionId: Guid) IssuedDate: DateTime
    var
        CurrentValue: Text;
    begin
        if IsolatedStorage.Contains(StrSubstNo(IssueDateFormatTok, ExtensionId), DataScope::Module) then
            if IsolatedStorage.Get(StrSubstNo(IssueDateFormatTok, ExtensionId), DataScope::Module, CurrentValue) then
                Evaluate(IssuedDate, CurrentValue);
    end;

    /// <summary>
    /// Gets the license for extension from isolated storage.
    /// </summary>
    /// <param name="ExtensionId">The id of the extension</param>
    /// <returns>The license</returns>
    internal procedure GetLicense(ExtensionId: Guid) LicenseKey: Text
    var
        CurrentValue: Text;
    begin
        if IsolatedStorage.Contains(StrSubstNo(LicenseKeyFormatTok, ExtensionId), DataScope::Module) then
            if IsolatedStorage.Get(StrSubstNo(LicenseKeyFormatTok, ExtensionId), DataScope::Module, CurrentValue) then
                Evaluate(LicenseKey, CurrentValue);
    end;

    /// <summary>
    /// Gets the license service url from isolated storage.
    /// </summary>
    /// <returns>The license service url.</returns>
    internal procedure GetLicenseServiceUrl() ServiceUrl: Text
    begin
        if IsolatedStorage.Contains(ServiceUrlTok, DataScope::Module) then
            IsolatedStorage.Get(ServiceUrlTok, DataScope::Module, ServiceUrl);
    end;
}