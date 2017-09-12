name := "iterate-config"

version := "0.0.1"

organization := "org.hnl"

scalaVersion := "2.12.3"

scalacOptions += "-target:jvm-1.8"

/*
 * assembly options
 */
assemblyJarName in assembly := "hiveConfig.jar"
mainClass in assembly := Some("org.hnl.hive.cfg.GenerateHiveConfig")

libraryDependencies ++= {
  Seq(
  	"org.clapper"                      %% "grizzled-scala"         % "4.2.0",
  	"com.typesafe"                      % "config"                 % "1.3.1",
  	"com.jsuereth"                     %% "scala-arm"              % "2.0",
	"org.scodec"                       %% "scodec-stream"          % "1.0.1",
	"org.json4s"                       %% "json4s-native"          % "3.5.2",
	"com.beachape"                     %% "enumeratum-json4s"      % "1.5.13",
  	
  	"org.clapper"                      %% "grizzled-slf4j"         % "1.3.0",
  	"ch.qos.logback"                    % "logback-classic"        % "1.2.3",
  	
    "org.scalatest"                    %% "scalatest"              % "3.0.1"                % "test"
    
  )
}

