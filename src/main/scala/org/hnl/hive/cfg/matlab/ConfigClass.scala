package org.hnl.hive.cfg.matlab

import org.hnl.hive.cfg.TreatmentConfig

/**
 * ConfigClass
 * <p>
 * Created on Mar 1, 2016.
 * <p>
 *
 * @author Jason White
 */
case class ConfigClass(cfg: TreatmentConfig) extends MatlabChunk with MatlabFormatting {

  def toMatlab: String = s"""
classdef Config
    % configuration information for HIVE treatment ${lit(cfg.name)}

    properties (Constant)
        % treatment definition
        name            = ${lit(cfg.name)}
        trainingSetId   = ${lit(cfg.trainingSetId.toInt)}
        trainingStyleId = ${lit(cfg.trainingStyleId.toInt)}
        clusterStyleId  = ${lit(cfg.clusterStyleId.toInt)}
        alphaSelectId   = ${lit(cfg.alphaSelectId.toInt)}
        muSelectId      = ${lit(cfg.muSelectId.toInt)}

        % treatment directories
        projectRoot  = ${lit(cfg.projectRoot)}
        trainingPath = ${lit(cfg.trainingPath)}
        modelPath    = ${lit(cfg.modelPath)}
        clusterPath  = ${lit(cfg.clusterPath)}
        alphaPath    = ${lit(cfg.alphaPath)}
        muPath       = ${lit(cfg.muPath)}

    end
end

"""

}
