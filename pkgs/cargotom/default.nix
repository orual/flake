{
  fetchFromGitHub,
  lib,
  rustPlatform,
  openssl,
  pkg-config,
}:
rustPlatform.buildRustPackage rec {
  pname = "cargotom";
  version = "2.3.8";

  src = fetchFromGitHub {
    owner = "frederik-uni";
    repo = "cargotom";
    rev = "${version}";
    sha256 = "sha256-vAqpJRmiANTqyv30T0hcinXn4aQNTCOBzWsbLs6FA6w=";
  };

  cargoHash = "sha256-JJ+dkAgAMDLNxaoy0fmx++ldUPlYm281LtqVZ8pM5Lg=";

  buildInputs = [
    openssl
  ];

  nativeBuildInputs = [
    pkg-config
  ];
  meta = with lib; {
    description = "CargoTom[l] LSP";
    homepage = "https://github.com/frederik-uni/cargotom";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
