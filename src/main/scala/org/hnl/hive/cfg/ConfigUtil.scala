package org.hnl.hive.cfg

import java.nio.file.FileSystems
import java.util.ArrayList

import scala.collection.JavaConversions._
import scala.language.implicitConversions

import com.typesafe.config._

import grizzled.slf4j.Logging

// scalastyle:off null

/**
 * ConfigUtil
 * <p>
 * Created on Mar 15, 2016.
 * <p>
 *
 * @author Jason White
 */
object ConfigUtil {
  implicit def configToWrappedConfig(config: Config): WrappedConfig =
    new WrappedConfig(config)
}

/**
 * WrappedConfig
 * <p>
 * Created on Mar 15, 2016.
 * <p>
 *
 * @author Jason White
 */
class WrappedConfig(config: Config) extends Logging {

  /**
   * getString
   * @param key
   * @return
   */
  def getString(key: String): String = doTry {
    config.getString(key)
  }

  /**
   * getString
   * @param key
   * @param fallback
   * @return
   */
  def getString(key: String, fallback: String): String = doTry {
    if (config.hasPath(key)) {
      config.getString(key)
    }
    else {
      info(s"no value found for '${key}', using '${fallback}'")
      fallback
    }
  }

  /**
   * getInt
   * @param key
   * @return
   */
  def getInt(key: String): Int = doTry {
    config.getInt(key)
  }

  /**
   * getIntList
   * @param key
   * @return
   */
  def getIntList(key: String): List[Int] = doTry {
    config.getIntList(key).map(_.toInt).toList
  }

  /**
   * getDouble
   * @param key
   * @return
   */
  def getDouble(key: String): Double = doTry {
    config.getDouble(key)
  }

  def getDoubleList(key: String): List[Double] = doTry {
    config.getDoubleList(key).map(_.toDouble).toList
  }

  /**
   * getAbsolutePath
   * @param key
   * @return
   */
  def getAbsolutePath(key: String): String = doTry {
    toAbsolutePath(config.getString(key))
  }

  /**
   * getIntVectorList
   * @param key
   * @return
   */
  def getIntVectorList(key: String): List[List[Int]] = doTry {
    val value = config.getValue(key)

    def asList[A](v: ConfigValue)(f: ConfigValue => A): List[A] =
      v.asInstanceOf[ConfigList].toList.map { e => f(e) }

    def asInt(v: ConfigValue): Int =
      v.unwrapped().asInstanceOf[Number].intValue

    getDeepValueType(value) match {
      case List(ConfigValueType.LIST, ConfigValueType.LIST, ConfigValueType.NUMBER) => asList(value)(v => asList(v)(e => asInt(e)))
      case List(ConfigValueType.LIST, ConfigValueType.NUMBER) => List(asList(value)(v => asInt(v)))
      case List(ConfigValueType.NUMBER) => List(List(asInt(value)))
    }
  }

  /**
   * getAbsolutePathList
   * @param key
   * @return
   */
  def getAbsolutePathList(key: String): List[String] = doTry {
    val value: ConfigValue = config.getValue(key)
    val kind: ConfigValueType = value.valueType

    kind match {
      case ConfigValueType.LIST => config.getStringList(key).toList.map(s => toAbsolutePath(s))
      case ConfigValueType.NULL => Nil
      case _                    => List(toAbsolutePath(value.unwrapped().toString))
    }
  }

  /**
   * getObjectList
   * @param key
   * @return
   */
  def getObjectList(key: String): List[WrappedConfig] = doTry {
    config.getObjectList(key).map { o => new WrappedConfig(o.toConfig()) }.toList
  }

  /*
   * INTERNAL API
   */
  protected def toAbsolutePath(dir: String): String =
    FileSystems
      .getDefault
      .getPath(dir)
      .normalize
      .toAbsolutePath
      .toString

  protected def getDeepValueType(value: ConfigValue): List[ConfigValueType] = {
    value.valueType match {
      case l @ ConfigValueType.LIST => l :: getDeepValueType(value.asInstanceOf[ConfigList].get(0))
      case e @ _                    => e :: Nil
    }
  }

  protected def doTry[A](f: => A): A = {
    try {
      f
    }
    catch {
      case e: ConfigException if config.origin != null && config.origin.lineNumber > 0 => {
        val e2 = new HiveConfigException(s"in ${config.origin.filename} on line ${config.origin.lineNumber}: ${e.getMessage}")
        e2.setStackTrace(e.getStackTrace)
        throw e2
      }
    }
  }
}

/**
 * HiveConfigException
 * <p>
 * Created on Mar 15, 2016.
 * <p>
 *
 * @author Jason White
 */
class HiveConfigException(message: String = null, cause: Throwable = null) extends Exception(message, cause)
