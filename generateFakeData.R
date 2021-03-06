# RScrpit for generate fake data in csv mode

library(dplyr)
library(tidyverse)
library(hms)
library(charlatan)

## First Step: from some real data, create new fake data and aggregate them togheter
## Dataframe to work: cliente, classe_possibile, giorni_della_settimana, compagnia_aerea, tipo_di_aereoplano, aereoporto

dfAeroporti <- read.csv("./csv/Aeroporto.csv")
dfTipoAereoplano <- read.csv("./csv/TipoDiAeroplano.csv")
dfGiorniSettimana <- read.csv("./csv/GiorniDellaSettimana.csv")
dfClassi <- read.csv("./csv/ClassePossibile.csv")
dfAereoplani <- read.csv("./csv/Aeroplano.csv")
dfCompagniaAerea <- read.csv("./csv/CompagniaAerea.csv")


#fakeAereports <- simulate_dataset(dfAeroporti, n=80)
#fakeAereports <- rbind(dfAeroporti, fakeAereports) %>%
#  distinct(Airport_code, .keep_all = TRUE)


## Second step
## 

# Dati due vettori di valori unvoci, la funzione crea un df contente un sample del prodotto cartesiano tra i due vettori
generateCartesianProd <- function(n = 1, ...){
  karg <- list(...)
  tmp_df <- cross_df(karg) %>%
            unique() %>%
            sample_n(n)
  return(tmp_df)
}

# Funzione per creare custom ID secondo un template
# # = è un cifra, ? = è un carattere alfabetico
generateID <- function(n=1, id_format="##") {
  tmpVec = c()
  item = 1
  
  #recursive function for generate a list of different ids
  aux <- function(i, id, n, vec) {
    (x <- BaseProvider$new())
    if (i <= n) {
      vec[i] <- x$bothify(id)
      i <- i + 1
      aux(i, id, n, vec)
    } else {
      return(vec)
    }
  }
  
  # uppercase all the alfa-character
  result <- aux(item, id_format, n, tmpVec) %>%
    lapply(., function(v) {
      if(is.character(v))
        return(toupper(v))
      else
        return(v)
    })
  
  return(result)
}

# Funzione per generare orario nella forma "16:20"
generateTime <- function(n=1, hour=0, minute=23) {
  hours <- as.character(ch_integer(n = n, min = hour, max = 23))
  minutes <- as.character(ch_integer(n = n, min = minute, max = 59))
  return(paste(hours, minutes, sep = ":"))
}

# Funzione per generare orario "sensati" (ovvero che avvegano dopo) dato
# in input un vettore formato da date del tipo "HH:MM"
generateSensibleTime <- function(x=c()) {
  lapply(x, function(v) {
    l <- unlist(str_split(v, ":"))
    t <- generateTime(hour = as.integer(l[1]),
                      minute = as.integer(l[2]))
    return(t)
  }) %>%
    unlist()
}

generatePrice <- function(n=1) {
  x <- ch_double(n=n, mean=70, sd = 20)
  unlist(map(x, function(v) {
    if (v < 0)
      return(format(round(abs(v),2), nsmall=2))
    else if (v < 20) {
      v <- v + ch_integer(min = v, max=100)
      return(format(round(v,2), nsmall=2))
    }
    else
      return(format(round(v,2), nsmall=2))
  }))
}




# Può decollare
puoDecollare <- generateCartesianProd(50, tipo_aeroplano = dfTipoAereoplano$nome,
                                       aeroporto = dfAeroporti$codice)

# Tratta
# Tratta ID -> T####
tratta <- generateCartesianProd(50, aeroporto_arrivo = dfAeroporti$codice,
                                aeroporto_partenza = dfAeroporti$codice) %>%
          subset(aeroporto_arrivo != aeroporto_partenza) # non lo stesso aereoporto di arrivo e partenza

tratta$id <- generateID(nrow(tratta), id_format = "T####")
tratta$orario_partenza <- generateTime(nrow(tratta))
tratta$orario_previsto_arrivo <- generateSensibleTime(tratta$orario_partenza)

# Compagnia Aerea Aereoplano
compagniaAereaAereoplano <- generateCartesianProd(50, compagnia_aerea = dfCompagniaAerea$nome,
                                                  aereoplano = dfAereoplani$codice)



# Clienti
clients <- ch_generate('name', 'phone_number', n = 100, locale = "it_IT")
colnames(clients) <- c("nome","telefono")
clients$nome <- gsub(pattern = "Sig. |Sig.ra |Dott. ", replacement = "", x = clients$nome)
clients$codice_fiscale <- generateID(n=nrow(clients), id_format = "??????##?##???#?")
clients <- clients %>% separate("nome", c("nome","cognome"), extra = "merge")
clients <- clients[, c("codice_fiscale","nome","cognome","telefono")]


# Volo
volo <- generateCartesianProd(50, aeroporto_arrivo=dfAeroporti$codice,
                              aeroporto_partenza=dfAeroporti$codice) %>%
  subset(aeroporto_arrivo != aeroporto_partenza)
volo$codice <- generateID(n = nrow(volo), id_format = "V?###")
volo$orario_partenza <- generateTime(nrow(volo))
volo$orario_previsto_arrivo <- generateSensibleTime(volo$orario_partenza)


# Classe di Volo
classeDiVolo <- generateCartesianProd(30, classe=dfClassi$Priorita,
                                      volo = volo$codice)
classeDiVolo$prezzo <- generatePrice(nrow(classeDiVolo))

#Volo Tratta
voloTratta <- generateCartesianProd(50, tratta=tratta$id,
                                    volo=volo$codice)
#TODO: numero progressivo?


# Prenotazione
prenotazione <- generateCartesianProd(30, cliente=clients$codice_fiscale,
                                      volo = classeDiVolo$volo,
                                      classse = classeDiVolo$classe)
prenotazione$codice <- generateID(nrow(prenotazione), id_format = "P###")








