# Experiment with CDK and JRuby

JRuby is making Java world visible from Ruby perspective.

Lets look at Java version of AWS CDK and try to use Ruby language to build infrastructure.

0. Before you start make sure you can use cdk using Java, it will ensure you have Java environment installed correctly. We will need tools like Maven installed.

https://docs.aws.amazon.com/cdk/latest/guide/work-with-cdk-java.html

1. Install JRuby

  I was using chruby and ruby-install

  https://github.com/postmodern/ruby-install
  https://github.com/postmodern/chruby

  but it should work with RVM as well

  https://rvm.io/interpreters/jruby

2. Dependencies

CDK for Java is generating default Maven pom.xml file.

If we add "maven-assembly-plugin" we can package all dependencies in one file so it's easier to use it from JRuby.

```
<plugin>
  <artifactId>maven-assembly-plugin</artifactId>
  <configuration>
    <archive>
      <manifest>
        <mainClass>com.myorg.Foo</mainClass>
      </manifest>
    </archive>
    <descriptorRefs>
      <descriptorRef>jar-with-dependencies</descriptorRef>
    </descriptorRefs>
  </configuration>
</plugin>
```

Now you can build all java dependencies as a one file target/cdk-jruby-0.1-jar-with-dependencies.jar

with `./install_dependencies.sh`

or

```
mvn clean compile assembly:single
```

3. When we do `cdk synth` we want to call ruby script instead so please update cdk.json accordingly:

```
{
  "app": "./build_stack.sh"
}
```

```
#!/bin/sh
jruby -r java \
  -r "./target/cdk-jruby-0.1-jar-with-dependencies.jar" \
  -r ./app/stack.rb
```

4. Now we are ready to create our stack using ruby (app/stack.rb):

```
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
```

5. Finally run `cdk synth` wait a bit ... little bit longer and you should see CloudFormation yaml output on your screen.

6. For more advanced example please check: examples/bigger_stack_with_fargate.rb

7. If you need to add some other dependencies update pom.xml and run ./install_dependencies.sh again.

8. The whole process of starting Java virtual machine is little bit slow, so you can use
console.sh script to start console with dependencies first, check the syntax and update app/stack.rb when you know something works.

```
#!/bin/sh
jirb -r java \
  -r "./target/cdk-jruby-0.1-jar-with-dependencies.jar" \
  -r ./console.rb
```

```
module CDKConsole
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

puts "example: >>> CDKConsole::Runtime::RUBY_2_5"
```

Other way could be to start server with dependencies and call synth from the client. To make it work you need to make sure server process has CDK_* environment set correctly, normally variables are set when you run command line `cdk` script.

Havefun!!!

