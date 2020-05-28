module CDK
  import 'software.amazon.awscdk.core.App'
  import 'software.amazon.awscdk.core.Construct'
  import 'software.amazon.awscdk.core.Stack'
  import 'software.amazon.awscdk.services.s3.Bucket'

  import 'software.amazon.awscdk.services.lambda.Code'
  import 'software.amazon.awscdk.services.lambda.Runtime'
  import 'software.amazon.awscdk.services.lambda.SingletonFunction'
  import 'software.amazon.awscdk.services.events.Schedule'
  import 'software.amazon.awscdk.services.events.targets.LambdaFunction'
  import 'software.amazon.awscdk.services.events.Rule'
end

puts "example: >>> CDK::Runtime::RUBY_2_5"
