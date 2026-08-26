using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace MyDent.Common.Services.CryptoService
{
    public class CryptoService : ICryptoService
    {
        // OWASP's 2023 minimum for PBKDF2-HMAC-SHA256 (up from the previous 10,000 here, which is
        // far below current guidance). The iteration count is stored alongside the hash (see
        // format below) instead of hardcoded, so raising it later never invalidates hashes already
        // in the database — each one is verified with whatever count it was created under.
        private const int Iterations = 210_000;

        // "{iterations}:{base64hash}" — self-describing so Verify always uses the count a given
        // hash was actually generated with. Hashes from before this change have no ':' (just the
        // raw base64 output of the old hardcoded-10000 call) and are verified via the legacy path.
        public string GenerateHash(string password, string salt)
        {
            return $"{Iterations}:{ComputeHash(password, salt, Iterations)}";
        }

        private static string ComputeHash(string password, string salt, int iterations)
        {
            using (var pbkdf2 = new Rfc2898DeriveBytes(password, Encoding.UTF8.GetBytes(salt), iterations, HashAlgorithmName.SHA256))
            {
                byte[] hash = pbkdf2.GetBytes(20);
                return Convert.ToBase64String(hash);
            }
        }

        public string GenerateSalt()
        {
            byte[] saltBytes = RandomNumberGenerator.GetBytes(16);
            return Convert.ToBase64String(saltBytes);
        }

        public bool Verify(string hash, string salt, string password)
        {
            var separatorIndex = hash.IndexOf(':');
            if (separatorIndex < 0)
            {
                // Legacy hash, predating the embedded iteration count — always generated with 10000.
                return hash == ComputeHash(password, salt, 10000);
            }

            var iterations = int.Parse(hash.AsSpan(0, separatorIndex));
            var storedHash = hash[(separatorIndex + 1)..];
            return storedHash == ComputeHash(password, salt, iterations);
        }
    }
}
