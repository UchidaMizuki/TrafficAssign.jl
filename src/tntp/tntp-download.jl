function download_tntp(path=PATH_TNTP; overwrite=false)
  dir_tntp = joinpath(path, DIR_NAME_TNTP)

  if !isdir(dir_tntp) || overwrite
    file = tempname()
    download("https://github.com/bstabler/TransportationNetworks/archive/$(SHA_TNTP).zip", file)

    reader = ZipFile.Reader(file)

    for file in reader.files
      file_name = joinpath(path, file.name)

      if endswith(file_name, "/")
        if !isdir(file_name)
          mkdir(file_name)
        end
      else
        write(file_name, read(file))
      end
    end

    close(reader)
    rm(file)
  end

  return dir_tntp
end
