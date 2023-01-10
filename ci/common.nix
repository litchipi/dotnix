{...}: {
  base.user = "ci";
  base.hostname = "ci";

  cmn.software.enable = false;

  setup.is_ci_run = true;
}
