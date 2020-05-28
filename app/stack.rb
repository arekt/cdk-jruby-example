module CDK
  import 'software.amazon.awscdk.core.App'
  import 'software.amazon.awscdk.core.Stack'
  import 'software.amazon.awscdk.services.lambda.Code'
  import 'software.amazon.awscdk.services.lambda.Runtime'
  import 'software.amazon.awscdk.services.lambda.Function'
end

app = CDK::App.new()
stack = CDK::Stack.new(app, "CdkJrubyStack")
lambdaFunction = CDK::Function::Builder.create(stack, 'hello')
  .runtime(CDK::Runtime::RUBY_2_5)
  .handler('hello.handler')
  .code(CDK::Code.fromAsset('lambda'))
  .build()

app.synth()
