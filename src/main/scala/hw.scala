import grizzled.slf4j.Logging

object Hi extends Logging {
  def main(args: Array[String]) = {
    println("hi!")

    info("logged hello")
  }
}
