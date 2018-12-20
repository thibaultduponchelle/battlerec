mongo battlerec --eval 'db.battles.remove({})'

mongoimport -d battlerec -c battles --type csv --file data.csv --headerline
