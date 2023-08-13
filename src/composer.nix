nixpkgs: let
  readJsonSectionFromFile = file: section: default: let
    filepath = "${builtins.getEnv "PWD"}/${file}";
    filecontent =
      if builtins.pathExists filepath
      then builtins.fromJSON (builtins.readFile filepath)
      else {};
  in
    filecontent.${section} or default;

  getExtensionFromSection = section: let
    # Get "require" section to extract extensions later
    require = readJsonSectionFromFile "composer.json" section {};
    # Copy keys into values
    composerRequiresKeys = map (p: nixpkgs.lib.attrsets.mapAttrs' (k: v: nixpkgs.lib.nameValuePair k k) p) [require];
    # Convert sets into lists
    composerRequiresMap = map (package: (map (key: builtins.getAttr key package) (builtins.attrNames package))) composerRequiresKeys;
  in
    # Convert the set into a list, filter out values not starting with "ext-", get rid of the first 4 characters from the name
    map (x: builtins.substring 4 (builtins.stringLength x) x) (builtins.filter (x: (builtins.substring 0 4 x) == "ext-") (nixpkgs.lib.flatten composerRequiresMap));

  composer = {
    inherit getExtensionFromSection;
    detectPhpVersion = phpMatrix: let
      require = readJsonSectionFromFile "composer.json" "require" {};
      default = phpMatrix.php81;
    in
      if builtins.hasAttr "php" require
      then
        phpMatrix
        .${
          "php"
          + builtins.replaceStrings ["."] [""] (
            builtins.head (builtins.match ".*([[:digit:]]\.[[:digit:]])" require.php)
          )
        }
        or default
      else default;
  };
in
  composer
