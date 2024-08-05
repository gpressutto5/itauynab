const transactions = angular
  .element(document.getElementById("appController"))
  .scope()
  .ac.cartoes.find((c) => c.numero === arguments[0])
  .faturas.filter((f) => !!f.lancamentosNacionais)
  .map((f) => ({
    international: f.lancamentosInternacionais.titularidades,
    national: f.lancamentosNacionais.titularidades,
  }));

const monthCombinedTransactions = transactions.reduce(
  (acc, transaction) => {
    acc.international = acc.international.concat(
      transaction.international || []
    );
    acc.national = acc.national.concat(transaction.national || []);
    return acc;
  },
  { international: [], national: [] }
);
monthCombinedTransactions.national = monthCombinedTransactions.national.reduce(
  (acc, month) => acc.concat(month.lancamentos),
  []
);
monthCombinedTransactions.international =
  monthCombinedTransactions.international.reduce(
    (acc, month) => acc.concat(month.lancamentos),
    []
  );

const parseTransaction = (transaction) => {
  let amount = Number(transaction.valor.replace(".", "").replace(",", "."));
  let outflow =
    transaction.sinalValor === "-" ? -amount : amount;
  let payee = transaction.descricao;
  const matches = payee.match(/(\d{2})\/(\d{2})$/);
  if (matches) {
    if (matches[1] !== "01") {
      return null;
    }
    const instalments = Number(matches[2]);
    outflow = Number((outflow * instalments).toFixed(2));
    payee = payee.replace(/ *\d{2}\/\d{2}$/, "");
  }
  return {
    date: transaction.data,
    outflow,
    payee,
  };
};

monthCombinedTransactions.national = monthCombinedTransactions.national
  .map(parseTransaction)
  .filter((transaction) => !!transaction);
monthCombinedTransactions.international =
  monthCombinedTransactions.international
    .map(parseTransaction)
    .filter((transaction) => !!transaction);

const allTransactions = monthCombinedTransactions.national.concat(monthCombinedTransactions.international);

return JSON.stringify(allTransactions);
