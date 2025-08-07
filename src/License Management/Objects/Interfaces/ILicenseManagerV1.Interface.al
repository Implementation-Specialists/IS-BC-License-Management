namespace IS.LicenseManagement;

interface "ISZ ILicense Manager V1"
{
    Access = Internal;

    /// <summary>
    /// Validate license for an extension.
    /// </summary>
    /// <param name="ExtensionId">Extension Id</param>
    /// <returns>True if license is valid; Otherwise false.</returns>
    procedure ValidateLicense(ExtensionId: Guid): Boolean
}