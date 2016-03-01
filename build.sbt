name := "iterate-config"

version := "0.0.1"

organization := "org.hnl"

scalaVersion := "2.11.7"

libraryDependencies ++= {
  Seq(
  	"org.clapper"                      %% "grizzled-scala"         % "1.4.0",
  	"com.typesafe"                      % "config"                 % "1.3.0",
//  "net.liftweb"                      %% "lift-common"            % "2.6.3",
  	
  	"org.clapper"                      %% "grizzled-slf4j"         % "1.0.2",
  	"ch.qos.logback"                    % "logback-classic"        % "1.1.5",
  	
    "org.scalatest"                    %% "scalatest"              % "2.2.6"                % "test"
  )
}

