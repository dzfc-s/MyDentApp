namespace MyDent.Model.Requests
{
    public class UserPasswordChangeRequest
    {
        public string Password { get; set; } = null!;
        public string NewPassword { get; set; } = null!;
        public string ConfirmNewPassword { get; set; } = null!;
    }
}
