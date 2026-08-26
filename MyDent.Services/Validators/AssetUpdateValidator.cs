using MyDent.Model.Requests;
using FluentValidation;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MyDent.Services.Validators
{
    public class AssetUpdateValidator : AbstractValidator<AssetUpdateRequest>
    {
        // Same allow-list/magic-byte check as AssetInsertValidator — Update must not be able to
        // swap in content that doesn't match its declared ContentType just because Insert enforces it.
        private static readonly Dictionary<string, Func<byte[], bool>> MagicByteCheckers = new()
        {
            ["image/png"] = bytes => bytes.Length >= 8
                && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47
                && bytes[4] == 0x0D && bytes[5] == 0x0A && bytes[6] == 0x1A && bytes[7] == 0x0A,
            ["image/jpeg"] = bytes => bytes.Length >= 3
                && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF,
            ["image/gif"] = bytes => bytes.Length >= 6
                && bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38
                && (bytes[4] == 0x37 || bytes[4] == 0x39) && bytes[5] == 0x61,
            ["image/webp"] = bytes => bytes.Length >= 12
                && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46
                && bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50
        };

        public AssetUpdateValidator()
        {
            RuleFor(x => x.Id)
                .GreaterThan(0).WithMessage("Id is required and must be greater than 0.");

            RuleFor(x => x.FileName)
                .NotEmpty().WithMessage("FileName is required.")
                .MaximumLength(100).WithMessage("FileName cannot exceed 100 characters.");

            RuleFor(x => x.ContentType)
                .NotEmpty().WithMessage("ContentType is required.")
                .MaximumLength(100).WithMessage("ContentType cannot exceed 100 characters.")
                .Must(contentType => MagicByteCheckers.ContainsKey(contentType.ToLowerInvariant()))
                .WithMessage($"ContentType must be one of: {string.Join(", ", MagicByteCheckers.Keys)}.");

            RuleFor(x => x.Base64Content)
                .NotEmpty().WithMessage("Base64Content is required.");

            RuleFor(x => x)
                .Must(HaveContentMatchingItsDeclaredType)
                .WithMessage("File content does not match its declared ContentType.")
                .When(x => !string.IsNullOrEmpty(x.ContentType)
                    && MagicByteCheckers.ContainsKey(x.ContentType.ToLowerInvariant())
                    && !string.IsNullOrEmpty(x.Base64Content));
        }

        private static bool HaveContentMatchingItsDeclaredType(AssetUpdateRequest request)
        {
            byte[] bytes;
            try
            {
                bytes = Convert.FromBase64String(request.Base64Content);
            }
            catch (FormatException)
            {
                return false;
            }

            return MagicByteCheckers[request.ContentType.ToLowerInvariant()](bytes);
        }
    }
}
