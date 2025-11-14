{
  pkgs,
  lib,
  ...
}: let
  mkIosevkaorual = {
    spacing,
    name,
  }:
    pkgs.iosevka.override
    {
      privateBuildPlan = {
        family = "Ioskeley Mono ${name}";
        spacing = spacing;
        serifs = "sans";
        noCvSs = false;
        exportGlyphNames = false;
        variants = {
          inherits = "ss15";
          design = {
            one = "no-base";
            two = "straight-neck-serifless";
            three = "flat-top-serifless";
            four = "semi-open-serifless";
            five = "oblique-flat-serifless";
            six = "open-contour";
            seven = "straight-serifless";
            eight = "two-circles";
            nine = "open-contour";
            zero = "dotted";
            capital-a = "straight-serifless";
            capital-b = "standard-serifless";
            capital-c = "bilateral-inward-serifed";
            capital-d = "standard-serifless";
            capital-e = "serifless";
            capital-f = "serifless";
            capital-g = "toothless-corner-inward-serifed-hooked";
            capital-h = "serifless";
            capital-i = "serifed";
            capital-j = "serifless";
            capital-k = "symmetric-touching-serifless";
            capital-l = "serifless";
            capital-m = "hanging-serifless";
            capital-n = "standard-serifless";
            capital-p = "closed-serifless";
            capital-q = "crossing";
            capital-r = "standing-serifless";
            capital-s = "serifless";
            capital-t = "serifless";
            capital-u = "toothless-rounded-serifless";
            capital-v = "straight-serifless";
            capital-w = "straight-flat-top-serifless";
            capital-x = "straight-serifless";
            capital-y = "straight-serifless";
            capital-z = "straight-serifless";
            a = "double-storey-serifless";
            b = "toothed-serifless";
            c = "bilateral-inward-serifed";
            d = "toothed-serifless";
            e = "flat-crossbar";
            f = "flat-hook-serifless-crossbar-at-x-height";
            g = "single-storey-serifless";
            h = "straight-serifless";
            i = "serifed";
            j = "flat-hook-serifed";
            k = "symmetric-touching-serifless";
            l = "serifed";
            m = "serifless";
            n = "straight-serifless";
            p = "eared-serifless";
            q = "straight-serifless";
            r = "hookless-serifless";
            s = "serifless";
            t = "flat-hook-short-neck2";
            u = "toothed-serifless";
            v = "straight-serifless";
            w = "straight-flat-top-serifless";
            x = "straight-serifless";
            y = "straight-serifless";
            z = "straight-serifless";
            lower-theta = "oval";
            tittle = "square";
            diacritic-dot = "square";
            punctuation-dot = "square";
            braille-dot = "square";
            tilde = "low";
            asterisk = "penta-mid";
            underscore = "high";
            caret = "medium";
            ascii-grave = "straight";
            ascii-single-quote = "straight";
            paren = "flat-arc";
            brace = "curly-flat-boundary";
            guillemet = "straight";
            number-sign = "slanted";
            ampersand = "closed";
            at = "fourfold";
            dollar = "through";
            cent = "through-cap";
            percent = "rings-continuous-slash";
            bar = "natural-slope";
            question = "corner";
            pilcrow = "high";
            micro-sign = "toothed-serifless";
            decorative-angle-brackets = "middle";
            lig-ltgteq = "slanted";
            lig-neq = "slightly-slanted";
            lig-equal-chain = "without-notch";
            lig-hyphen-chain = "without-notch";
            lig-plus-chain = "without-notch";
            lig-double-arrow-bar = "without-notch";
            lig-single-arrow-bar = "without-notch";
          };
          weights = {
            Regular = {
              shape = 400;
              menu = 400;
              css = 400;
            };
            Bold = {
              shape = 700;
              menu = 700;
              css = 700;
            };
            Light = {
              shape = 300;
              menu = 300;
              css = 300;
            };
            Medium = {
              shape = 500;
              menu = 500;
              css = 500;
            };
            SemiBold = {
              shape = 600;
              menu = 600;
              css = 600;
            };
            ExtraBold = {
              shape = 800;
              menu = 800;
              css = 800;
            };
            Normal = {
              shape = 600;
              menu = 5;
              css = "normal";
            };
          };
          slopes = {
            Upright = {
              angle = 0;
              shape = "upright";
              menu = "upright";
              css = "normal";
            };
            Italic = {
              angle = 11.8;
              shape = "italic";
              menu = "italic";
              css = "italic";
            };
          };
          ligations = {
            inherits = "dlig";
          };
          metricOverride = {
            xHeight = 520;
            cap = 690;
            ascender = 740;
            sb = 85; # Perfect

            accentWidth = 182;
            accentClearance = 76;
            accentHeight = 162;
            accentStackOffset = 208;

            leading = 1250;
            parenSize = 860;
            dotSize = "blend(weight, [100, 110], [400, 125], [900, 150])";
            periodSize = 140;

            essRatio = 1.03;
            essRatioUpper = 1.03;
            essRatioLower = 1.03;
            essRatioQuestion = 1.03;
            archDepth = 152;
            smallArchDepth = 157;
          };
        };
      };
      set = "Ioskeley${name}";
    };
  iosevkaOrualTerm = mkIosevkaorual {
    spacing = "term";
    name = "Term";
  };
  iosevkaOrual = mkIosevkaorual {
    spacing = "normal";
    name = "";
  };
  iosevkaOrualEtoile = mkIosevkaorual {
    spacing = "quasi-proportional";
    name = "Etoile";
  };
in
  # let
  #   # all nerdfonts
  #   nerdfonts = builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
  # in
  {
    fonts.fontconfig.enable = true;

    # fonts
    home.packages = with pkgs; [
      # iosevka + variants
      iosevka-bin
      (iosevka-bin.override {variant = "Aile";})
      (iosevka-bin.override {variant = "Etoile";})
      (iosevka-bin.override {variant = "SS15";}) # ibm plex mono style
      iosevkaOrual
      # iosevkaOrualTerm
      # iosevkaOrualEtoile

      # nice monospace and bitmap fonts
      cozette
      tamzen
      departure-mono
      # tamsyn
      # requires `input-fonts.acceptLicense = true` in `config.nix`.
      input-fonts

      # some nice ui fonts
      roboto
      inter
      b612 # designed by Airbus for jet cockpit UIs!
      ibm-plex

      # noto, and friends --- manish says its good
      # this fixes unicode tofu, even if you don't actually use
      # noto as a UI font...
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      noto-fonts-monochrome-emoji
      # fontconfig binary
      fontconfig
      nerd-fonts.departure-mono
      nerd-fonts.hack
      nerd-fonts.noto
      nerd-fonts.ubuntu
      nerd-fonts.zed-mono
      nerd-fonts.monaspace
      nerd-fonts.iosevka
      nerd-fonts.iosevka-term
      nerd-fonts.iosevka-term-slab
    ];
    #++ nerdfonts;
  }
