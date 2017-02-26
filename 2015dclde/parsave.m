function parsave(saveFileName, detectionsToSave)
    var2str = @(x)inputname(1);
    save(saveFileName, var2str(detectionsToSave));
end