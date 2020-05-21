function appendDatasetInfo(filename, name, id, setId, sourceId, treatment)

    datasetInfo.name = name;
    datasetInfo.id = id;
    datasetInfo.setId = setId;
    datasetInfo.sourceId = sourceId;
    datasetInfo.treatment = treatment;
    
    save(filename, 'datasetInfo', '-append');

end

