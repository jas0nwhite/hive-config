package org.hnl.hive.cfg

import java.nio.file.FileSystems

import scala.collection.JavaConverters._
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
    *
    * @param key the key for the value
    * @return the value as a String
    */
  def getString(key: String): String = doTry {
    config.getString(key)
  }

  /**
    * getString
    *
    * @param key the key for the value
    * @param fallback the fallback (default) value
    * @return the value as String, or default
    */
  def getString(key: String, fallback: String): String = doTry {
    if (config.hasPath(key)) {
      config.getString(key)
    }
    else {
      info(s"no value found for '$key', using '$fallback'")
      fallback
    }
  }

  /**
    * getInt
    *
    * @param key the key for the value
    * @return the value as an int
    */
  def getInt(key: String): Int = doTry {
    config.getInt(key)
  }

  /**
    * getIntList
    *
    * @param key the key for the value
    * @return the value as a list of ints
    */
  def getIntList(key: String): List[Int] = doTry {
    config.getIntList(key).asScala.map(_.toInt).toList
  }

  /**
    * getDouble
    *
    * @param key the key for the value
    * @return the value as a double
    */
  def getDouble(key: String): Double = doTry {
    config.getDouble(key)
  }

  /**
    * getDoubleList
    *
    * @param key the key for the value
    * @return the value as a list of doubles
    */
  def getDoubleList(key: String): List[Double] = doTry {
    config.getDoubleList(key).asScala.map(_.toDouble).toList
  }

  /**
    * getAbsolutePath
    *
    * @param key the key for the value
    * @return the value as an absolute filepath
    */
  def getAbsolutePath(key: String): String = doTry {
    toAbsolutePath(config.getString(key))
  }

  /**
    * getIntVectorList
    *
    * @param key the key for the value
    * @return the value as an int vector list
    */
  def getIntVectorList(key: String): List[List[Int]] = doTry {
    val value = config.getValue(key)

    def asList[A](v: ConfigValue)(f: ConfigValue => A): List[A] =
      v.asInstanceOf[ConfigList].asScala.map { e => f(e) }.toList

    def asInt(v: ConfigValue): Int =
      v.unwrapped().asInstanceOf[Number].intValue

    getDeepValueType(value) match {
      case List(ConfigValueType.LIST, ConfigValueType.LIST, ConfigValueType.NUMBER) => asList(value)(v => asList(v)(e => asInt(e)))
      case List(ConfigValueType.LIST, ConfigValueType.NUMBER)                       => List(asList(value)(v => asInt(v)))
      case List(ConfigValueType.NUMBER)                                             => List(List(asInt(value)))
    }
  }

  /**
    * getAbsolutePathList
    *
    * @param key the key for the value
    * @return the value as a list of absolute filepaths
    */
  def getAbsolutePathList(key: String): List[String] = doTry {
    val value: ConfigValue = config.getValue(key)
    val kind: ConfigValueType = value.valueType

    kind match {
      case ConfigValueType.LIST => config.getStringList(key).asScala.map(s => toAbsolutePath(s)).toList
      case ConfigValueType.NULL => Nil
      case _                    => List(toAbsolutePath(value.unwrapped().toString))
    }
  }

  /**
    * getObjectList
    *
    * @param key the key for the value
    * @return the value as a list of config objects
    */
  def getObjectList(key: String): List[WrappedConfig] = doTry {
    config.getObjectList(key).asScala.map { o => new WrappedConfig(o.toConfig) }.toList
  }

  /**
    * getConfigObject
    *
    * @param key the key for the value
    * @return the value as a config object
    */
  def getConfigObject(key: String): Config = doTry {
    config.getObject(key).toConfig
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
      case l@ConfigValueType.LIST => l :: getDeepValueType(value.asInstanceOf[ConfigList].get(0))
      case e@_                    => e :: Nil
    }
  }

  protected def doTry[A](f: => A): A = {
    try {
      f
    }
    catch {
      case e: ConfigException if config.origin != null && config.origin.lineNumber > 0 =>
        val e2 = new HiveConfigException(s"in ${config.origin.filename} on line ${config.origin.lineNumber}: ${e.getMessage}")
        e2.setStackTrace(e.getStackTrace)
        throw e2
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
