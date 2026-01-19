ExUnit.start()

# Define mocks
Mox.defmock(VisualMailer.MjmlMock, for: VisualMailer.Renderer.MjmlCompiler)
