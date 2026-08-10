using MyDent.Model.Requests;
using FluentValidation;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MyDent.Services.Validators
{
    public class AssetInsertValidator : AbstractValidator<AssetInsertRequest>
    {
        public AssetInsertValidator()
        {
            RuleFor(x => x.FileName)
                .NotEmpty().WithMessage("FileName is required.")
                .MaximumLength(100).WithMessage("FileName cannot exceed 100 characters.");

            RuleFor(x => x.ContentType)
                .NotEmpty().WithMessage("ContentType is required.")
                .MaximumLength(100).WithMessage("ContentType cannot exceed 100 characters.");

            RuleFor(x => x.Base64Content)
                .NotEmpty().WithMessage("Base64Content is required.");
        }
    }
}
