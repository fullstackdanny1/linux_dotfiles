# Ajutor pentru scripturile din ./scripts: fiecare devine un pachet cu
# dependențele în PATH (și verificat cu shellcheck la build).
{ pkgs }:
{
  mkScript =
    {
      name,
      runtimeInputs ? [ ],
      env ? { },
    }:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      runtimeEnv = env;
      text = builtins.readFile (./scripts + "/${name}.sh");
    };
}
