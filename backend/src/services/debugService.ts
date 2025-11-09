import { erpClient } from "../clients/erpClient";
import { normalizeCashflows } from "../utils/cashflow";
import { ensureIsoDate } from "../utils/date";

interface DebugParams {
  email?: string;
  contactId?: number;
  from?: string;
  to?: string;
}

export const getDebugInvestorFundSources = async ({ email, contactId, from, to }: DebugParams) => {
  if (!email && !contactId) {
    throw new Error("email or contactId is required");
  }

  const toDate = ensureIsoDate(to ?? new Date().toISOString().slice(0, 10));
  const fromDate = ensureIsoDate(from ?? "1900-01-01");

  const contactRecord =
    contactId != null ? await erpClient.getContact(contactId) : await findContactByEmail(email as string);

  if (!contactRecord) {
    throw new Error("Contact not found");
  }

  const contact = contactRecord;

  const mappings = await erpClient.getAccountContactMappings(contact.contact_id);
  const accountIds = [...new Set(mappings.map((map) => map.account_id))];

  const fundsFromMappings = mappings
    .map((map) => map.fund_id)
    .filter((fundId): fundId is number => typeof fundId === "number");

  const commitments = await erpClient.getCommitments();
  const fundsFromCommitments = commitments
    .filter((commitment) => accountIds.includes(commitment.account_id))
    .map((commitment) => commitment.fund_id);

  const cashflows = await erpClient.getCashflows({
    startDate: "1900-01-01",
    endDate: toDate,
  });
  const accountCashflows = cashflows.filter((flow) => accountIds.includes(flow.account_id));
  const fundsFromCashflows = [
    ...new Set(accountCashflows.map((flow) => flow.fund_id)),
  ];

  const union = new Set<number>([
    ...fundsFromMappings,
    ...fundsFromCommitments,
    ...fundsFromCashflows,
  ]);

  const { flows } = normalizeCashflows(accountCashflows);
  const fundsList = await erpClient.getFunds();
  const fundsById = new Map(fundsList.map((fund) => [fund.fund_id, fund]));

  const perFund = [...union].map((fundId) => {
    const rawFlows = accountCashflows.filter((flow) => flow.fund_id === fundId);
    const normalizedFlows = flows.filter((flow) => flow.fundId === fundId);
    const inRange = normalizedFlows.filter((flow) => flow.date >= fromDate && flow.date <= toDate);

    const contributionsInRange = inRange
      .filter((flow) => flow.type === "contribution")
      .reduce((sum, flow) => sum + Math.abs(flow.amount), 0);

    const distributionsInRange = inRange
      .filter((flow) => flow.type === "distribution")
      .reduce((sum, flow) => sum + flow.amount, 0);

    const lifeDates = rawFlows.map((flow) => flow.transaction_date);
    const sortedLifeDates = [...lifeDates].sort();
    const firstEverFlow = sortedLifeDates[0] ?? null;
    const lastEverFlow = sortedLifeDates.length > 0 ? sortedLifeDates[sortedLifeDates.length - 1] : null;

    const fundInfo = fundsById.get(fundId);

    return {
      fundId,
      fundName: fundInfo?.fundname ?? fundInfo?.shortname ?? `Fund ${fundId}`,
      contributionsInRange,
      distributionsInRange,
      firstEverFlow,
      lastEverFlow,
    };
  });

  return {
    contact: {
      id: contact.contact_id,
      name: contact.full_name,
      email: contact.reporting_email ?? "",
    },
    accountCount: accountIds.length,
    unionFundCount: union.size,
    sources: {
      fromMappings: fundsFromMappings.length,
      fromCommitments: fundsFromCommitments.length,
      fromCashflows: fundsFromCashflows.length,
    },
    perFund,
  };
};

const findContactByEmail = async (email: string) => {
  const results = await erpClient.searchContacts(email);
  return results.find(
    (contact) => contact.reporting_email?.toLowerCase() === email.toLowerCase(),
  );
};
