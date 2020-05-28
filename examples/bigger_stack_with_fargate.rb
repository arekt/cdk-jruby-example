require "java"

import 'software.amazon.awscdk.core.Construct'
import 'software.amazon.awscdk.core.Stack'
import 'software.amazon.awscdk.core.App'
import 'software.amazon.awscdk.services.s3.Bucket'
import 'software.amazon.awscdk.services.s3.assets.Asset'
import 'software.amazon.awscdk.services.lambda.Code'
import 'software.amazon.awscdk.services.lambda.Runtime'
import 'software.amazon.awscdk.services.lambda.Function'
import 'software.amazon.awscdk.services.events.Rule'
import 'software.amazon.awscdk.services.events.Schedule'
import 'software.amazon.awscdk.services.events.targets.LambdaFunction'
import 'software.amazon.awscdk.services.events.targets.EcsTask'
import 'software.amazon.awscdk.services.lambda.Code'
import 'software.amazon.awscdk.services.lambda.LayerVersion'
import 'software.amazon.awscdk.services.logs.LogGroup'
import 'software.amazon.awscdk.services.ecs.FargateTaskDefinition'
import 'software.amazon.awscdk.services.ecs.ContainerDefinitionOptions'
import 'software.amazon.awscdk.services.ecs.ContainerImage'
import 'software.amazon.awscdk.services.ecs.patterns.QueueProcessingFargateService'
import 'software.amazon.awscdk.services.ecs.Cluster'
import 'software.amazon.awscdk.services.ecs.LogDrivers'
import 'software.amazon.awscdk.services.ecs.AwsLogDriver'
import 'software.amazon.awscdk.services.ecs.FargateService'
import 'software.amazon.awscdk.services.events.targets.EcsTaskProps'
import 'software.amazon.awscdk.services.ec2.Vpc'
import 'software.amazon.awscdk.services.ec2.IVpc'
import 'software.amazon.awscdk.services.ec2.SubnetConfiguration'
import 'software.amazon.awscdk.services.ec2.SubnetType'
import 'software.amazon.awscdk.services.ec2.SecurityGroup'
import 'software.amazon.awscdk.services.ec2.Port'
import 'software.amazon.awscdk.services.ec2.Peer'
import 'software.amazon.awscdk.services.ecr.assets.DockerImageAsset'

app = App.new
stack = Stack.new(app, "CdkJrubyStack")

docker_image_asset = DockerImageAsset::Builder.create(stack, "UbuntuNodeJSImage")
  .directory(File.expand_path("docker_images/ubuntu_nodejs"))
  .build()

docker_image_asset2 = DockerImageAsset::Builder.create(stack, "ubuntu_ruby2.7")
  .directory(File.expand_path("docker_images/ubuntu_ruby2.7"))
  .build()

vpc = Vpc::Builder.create(stack, "MyVpc")
  .cidr("10.3.0.0/16")
  .subnetConfiguration([
    {
      "subnetType" => SubnetType::PUBLIC,
      "name" => "public"
    }
  ])
  .natGateways(0)
  .maxAzs(3)
  .build()

securityGroup = SecurityGroup::Builder.create(stack, "SG")
  .vpc(vpc)
  .description("Allow HTTP")
  .allowAllOutbound(true)
  .build()

securityGroup.addIngressRule(Peer.anyIpv4(), Port.tcp(3031))

task_definition = FargateTaskDefinition::Builder.create(stack, "TaskDef")
  .memoryLimitMiB(512)
  .cpu(256)
  .build();

docker_image = ContainerImage.fromDockerImageAsset(docker_image_asset)
docker_image2 = ContainerImage.fromDockerImageAsset(docker_image_asset2)

log_driver = AwsLogDriver::Builder.create()
  .streamPrefix('EventDemo')
  .build()

container1_definition = ContainerDefinitionOptions::Builder.new
  .image(docker_image)
  .environment({"LOCAL_TAG" => 'A'})
  .logging(log_driver)
  .build()

container2_definition = ContainerDefinitionOptions::Builder.new
  .image(docker_image)
  .environment({"LOCAL_TAG" => 'B'})
  .command(['/bin/bash','/opt/bin/run_job1.sh'])
  .logging(log_driver)
  .build()

container3_definition = ContainerDefinitionOptions::Builder.new
  .image(docker_image)
  .environment({"LOCAL_TAG" => 'C'})
  .command(['/bin/bash','/opt/bin/run_job2.sh'])
  .logging(log_driver)
  .build()

container4_definition = ContainerDefinitionOptions::Builder.new
  .image(docker_image2)
  .environment({"LOCAL_TAG" => 'C'})
  .logging(log_driver)
  .build()
  #TODO.logging(LogDrivers.awsLogs({"logRetention" => 31}))

task_definition
  .addContainer("redis-server", container1_definition)
task_definition
  .addContainer("worker1", container2_definition)
task_definition
  .addContainer("worker2", container3_definition)
# task_definition
#   .addContainer("sinatra_app", container4_definition)

imageAsset = Asset::Builder.create(stack, "SampleAsset")
  .path(File.expand_path("assets/example_image.png"))
  .build()

cluster = Cluster::Builder.create(stack, "MyCluster")
  .vpc(vpc)
  .build();

# TODO Fix it. Probably dont like vpc settings
# service = QueueProcessingFargateService::Builder.create(stack, "QueueProcessingService")
#   .image(docker_image)
#   .cluster(cluster)
#   .command(["pwd"])
#   .desiredTaskCount(1)
#   .memoryLimitMiB(512)
#   .cpu(256)
#   .build()

service = FargateService::Builder.create(stack, "MyService")
  .cluster(cluster)
  .taskDefinition(task_definition)
  .desiredCount(1)
  .assignPublicIp(true)
  .securityGroup(securityGroup)
  .vpcSubnets({"subnetName" => "public"})
  .build()

Bucket::Builder.create(stack, "CDKBucket")
  .versioned(false)
  .build()

my_layer = LayerVersion::Builder.create(stack, 'MyLayer')
  .code(Code.fromAsset('layers/my_layer'))
  .compatibleRuntimes([Runtime::RUBY_2_5])
  .license('TODO')
  .description('Example layer...')
  .build()

lambdaFunction = Function::Builder.create(stack, 'hello')
  .runtime(Runtime::RUBY_2_5)
  .handler('hello.handler')
  .code(Code.fromAsset('lambda'))
  .layers([my_layer])
  .build()

# l1 = Function::Builder.create(stack, 'store')
#   .runtime(Runtime::RUBY_2_5)
#   .handler('store.handler')
#   .code(Code.fromAsset('lambda'))
#   .build()

vpc.publicSubnets.each do |ps|
  puts "---"
  puts ps.availabilityZone
  puts ps.node.children.to_s
end

l2 = Function::Builder.create(stack, 'message')
  .runtime(Runtime::RUBY_2_5)
  .handler('message.handler')
  .code(Code.fromAsset('lambda'))
  .layers([my_layer])
  .environment({
    "S3_BUCKET_NAME" => imageAsset.getS3BucketName(),
    "S3_OBJECT_KEY" => imageAsset.getS3ObjectKey(),
    "S3_URL" => imageAsset.getS3Url(),
    "RUBYLIB" => "/opt/lib"
  })
  .build()

rule = Rule::Builder.create(stack, "cdk-lambda-cron-rule")
  .description("Run every hour")
  .schedule(Schedule.expression("cron(21 * ? * * *)"))
  .build()

rule.addTarget(LambdaFunction.new(lambdaFunction))

# task_props = EcsTaskProps::Builder.new()
#   .cluster(cluster)
#   .taskDefinition(task_definition)
#   .build()

rule2 = Rule::Builder.create(stack, "trigger-fat-lambda-rule")
  .description("Run every hour")
  .schedule(Schedule.expression("cron(30 * ? * * *)"))
  .build()
  #.targets([EcsTask.new(task_props)])

#rule2.addTarget(EcsTask.new(task_props))

#below is for service managed by ecs-cli

loggroup = LogGroup::Builder.create(stack, "ecs-cli-tutorial").build()
loggroup.grantWrite(task_definition.executionRole)

app.synth()

