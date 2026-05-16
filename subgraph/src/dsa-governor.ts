import { BigInt, Bytes } from "@graphprotocol/graph-ts"
import {
  ProposalCreated,
  VoteCast,
  ProposalQueued,
  ProposalExecuted
} from "../generated/DSAGovernor/DSAGovernor"
import { Proposal, Vote, Account, GovernanceInfo } from "../generated/schema"

function getOrCreateAccount(address: string): Account {
  let account = Account.load(address)
  if (!account) {
    account = new Account(address)
    account.delegatedVotes = BigInt.fromI32(0)
    account.save()
  }
  return account
}

function getGovernanceInfo(): GovernanceInfo {
  let info = GovernanceInfo.load("global")
  if (!info) {
    info = new GovernanceInfo("global")
    info.totalProposals = BigInt.fromI32(0)
    info.totalVotesCast = BigInt.fromI32(0)
    info.save()
  }
  return info
}

export function handleProposalCreated(event: ProposalCreated): void {
  let proposal = new Proposal(event.params.proposalId.toString())

  let proposer = getOrCreateAccount(event.params.proposer.toHexString())
  proposal.proposer = proposer.id

  proposal.targets = changetype<Bytes[]>(event.params.targets)
  proposal.values = event.params.values
  proposal.calldatas = event.params.calldatas
  proposal.description = event.params.description
  proposal.status = "Active"

  proposal.createdBlock = event.block.number
  proposal.createdTimestamp = event.block.timestamp
  proposal.save()

  let info = getGovernanceInfo()
  info.totalProposals = info.totalProposals.plus(BigInt.fromI32(1))
  info.save()
}
export function handleVoteCast(event: VoteCast): void {
  let voteId = event.params.proposalId.toString() + "-" + event.params.voter.toHexString()
  let vote = new Vote(voteId)

  vote.proposal = event.params.proposalId.toString()
  vote.voter = event.params.voter.toHexString()
  vote.support = event.params.support
  vote.weight = event.params.weight
  vote.reason = event.params.reason
  vote.save()

  let info = getGovernanceInfo()
  info.totalVotesCast = info.totalVotesCast.plus(BigInt.fromI32(1))
  info.save()
}
export function handleProposalQueued(event: ProposalQueued): void {
  let proposal = Proposal.load(event.params.proposalId.toString())
  if (proposal) {
    proposal.status = "Queued"
    proposal.save()
  }
}
export function handleProposalExecuted(event: ProposalExecuted): void {
  let proposal = Proposal.load(event.params.proposalId.toString())
  if (proposal) {
    proposal.status = "Executed"
    proposal.save()
  }
}