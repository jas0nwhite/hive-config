name := "hive-config"

version := "0.0.1"

organization := "org.hnl"

scalaVersion := "2.12.8"

scalacOptions += "-target:jvm-1.8"

/*
 * assembly options
 */
assemblyJarName in assembly := "hiveConfig.jar"
mainClass in assembly := Some("org.hnl.hive.cfg.GenerateHiveConfig")

libraryDependencies ++= {
  Seq(
    "org.clapper"                      %% "grizzled-scala"         % "4.10.0", // file utils, etc
    "com.typesafe"                      % "config"                 % "1.3.4", // HOCON config
    "com.jsuereth"                     %% "scala-arm"              % "2.0", // automatic resource management
    "org.scodec"                       %% "scodec-stream"          % "1.0.1", // streaming binary encoding/decoding
    "org.json4s"                       %% "json4s-native"          % "3.6.7", // standalone version of lift-json
    "com.beachape"                     %% "enumeratum-json4s"      % "1.5.15", // enumerations for json4s

    "org.clapper"                      %% "grizzled-slf4j"         % "1.3.0",
    "ch.qos.logback"                    % "logback-classic"        % "1.2.3",

    "org.scalatest"                    %% "scalatest"              % "3.0.8"                % "test"

  )
}

/*
libraryDependencies ++= {
  Seq(
    "org.clapper" %% "grizzled-scala" % "4.10.0", // file utils, etc
    "com.typesafe" % "config" % "1.3.4", // HOCON config
    "com.jsuereth" %% "scala-arm" % "2.0", // automatic resource management
    "org.scodec" %% "scodec-stream" % "1.2.1", // streaming binary encoding/decoding
    "org.json4s" %% "json4s-native" % "3.6.7", // standalone version of lift-json
    "com.beachape" %% "enumeratum-json4s" % "1.5.15", // enumerations for json4s

    "org.clapper" %% "grizzled-slf4j" % "1.3.4",
    "ch.qos.logback" % "logback-classic" % "1.2.3",

    "org.scalatest" %% "scalatest" % "3.0.8" % "test"

  )
}
 */