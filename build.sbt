name := "iterate-config"

version := "0.0.1"

organization := "org.hnl"

scalaVersion := "2.11.7"

/*
 * add Bintray repos
 */
seq(bintrayResolverSettings:_*)

libraryDependencies ++= {
  Seq(
  	"org.clapper"                      %% "grizzled-scala"         % "1.4.0",
  	
    "org.scalatest"                    %% "scalatest"              % "2.2.6"                % "test"
  )
}

