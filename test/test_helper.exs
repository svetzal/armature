ExUnit.start()

Armature.Registry.TestTracer.install()

for path <- Path.wildcard("test/support/inventory/*.exs") do
  Code.require_file(path)
end
