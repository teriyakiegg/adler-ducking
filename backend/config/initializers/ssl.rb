# Fix SSL certificate verification on macOS with Homebrew OpenSSL
cert_file = "/opt/homebrew/etc/openssl@3/cert.pem"

if File.exist?(cert_file)
  ENV["SSL_CERT_FILE"] ||= cert_file
end
