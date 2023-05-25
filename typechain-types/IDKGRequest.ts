/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
  PromiseOrValue,
} from "./common";

export declare namespace IDKGRequest {
  export type RequestStruct = {
    distributedKeyID: PromiseOrValue<BigNumberish>;
    R: PromiseOrValue<BigNumberish>[][];
    M: PromiseOrValue<BigNumberish>[][];
    result: PromiseOrValue<BigNumberish>[];
  };

  export type RequestStructOutput = [
    BigNumber,
    BigNumber[][],
    BigNumber[][],
    BigNumber[]
  ] & {
    distributedKeyID: BigNumber;
    R: BigNumber[][];
    M: BigNumber[][];
    result: BigNumber[];
  };
}

export interface IDKGRequestInterface extends utils.Interface {
  functions: {
    "getDistributedKeyID(bytes32)": FunctionFragment;
    "getM(bytes32)": FunctionFragment;
    "getProposalID(address,uint256,uint256)": FunctionFragment;
    "getR(bytes32)": FunctionFragment;
    "getRequest(bytes32)": FunctionFragment;
    "submitRequestResult(bytes32,uint256[])": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "getDistributedKeyID"
      | "getM"
      | "getProposalID"
      | "getR"
      | "getRequest"
      | "submitRequestResult"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "getDistributedKeyID",
    values: [PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: "getM",
    values: [PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: "getProposalID",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "getR",
    values: [PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: "getRequest",
    values: [PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: "submitRequestResult",
    values: [PromiseOrValue<BytesLike>, PromiseOrValue<BigNumberish>[]]
  ): string;

  decodeFunctionResult(
    functionFragment: "getDistributedKeyID",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "getM", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "getProposalID",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "getR", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "getRequest", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "submitRequestResult",
    data: BytesLike
  ): Result;

  events: {};
}

export interface IDKGRequest extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: IDKGRequestInterface;

  queryFilter<TEvent extends TypedEvent>(
    event: TypedEventFilter<TEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TEvent>>;

  listeners<TEvent extends TypedEvent>(
    eventFilter?: TypedEventFilter<TEvent>
  ): Array<TypedListener<TEvent>>;
  listeners(eventName?: string): Array<Listener>;
  removeAllListeners<TEvent extends TypedEvent>(
    eventFilter: TypedEventFilter<TEvent>
  ): this;
  removeAllListeners(eventName?: string): this;
  off: OnEvent<this>;
  on: OnEvent<this>;
  once: OnEvent<this>;
  removeListener: OnEvent<this>;

  functions: {
    getDistributedKeyID(
      _proposalID: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    getM(
      _proposalID: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<[BigNumber[][]]>;

    getProposalID(
      _dao: PromiseOrValue<string>,
      _distributedKeyID: PromiseOrValue<BigNumberish>,
      _timestamp: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[string]>;

    getR(
      _proposalID: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<[BigNumber[][]]>;

    getRequest(
      _proposalID: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<[IDKGRequest.RequestStructOutput]>;

    submitRequestResult(
      _proposalID: PromiseOrValue<BytesLike>,
      _result: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  getDistributedKeyID(
    _proposalID: PromiseOrValue<BytesLike>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  getM(
    _proposalID: PromiseOrValue<BytesLike>,
    overrides?: CallOverrides
  ): Promise<BigNumber[][]>;

  getProposalID(
    _dao: PromiseOrValue<string>,
    _distributedKeyID: PromiseOrValue<BigNumberish>,
    _timestamp: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<string>;

  getR(
    _proposalID: PromiseOrValue<BytesLike>,
    overrides?: CallOverrides
  ): Promise<BigNumber[][]>;

  getRequest(
    _proposalID: PromiseOrValue<BytesLike>,
    overrides?: CallOverrides
  ): Promise<IDKGRequest.RequestStructOutput>;

  submitRequestResult(
    _proposalID: PromiseOrValue<BytesLike>,
    _result: PromiseOrValue<BigNumberish>[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    getDistributedKeyID(
      _proposalID: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getM(
      _proposalID: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber[][]>;

    getProposalID(
      _dao: PromiseOrValue<string>,
      _distributedKeyID: PromiseOrValue<BigNumberish>,
      _timestamp: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<string>;

    getR(
      _proposalID: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber[][]>;

    getRequest(
      _proposalID: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<IDKGRequest.RequestStructOutput>;

    submitRequestResult(
      _proposalID: PromiseOrValue<BytesLike>,
      _result: PromiseOrValue<BigNumberish>[],
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {};

  estimateGas: {
    getDistributedKeyID(
      _proposalID: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getM(
      _proposalID: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getProposalID(
      _dao: PromiseOrValue<string>,
      _distributedKeyID: PromiseOrValue<BigNumberish>,
      _timestamp: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getR(
      _proposalID: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getRequest(
      _proposalID: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    submitRequestResult(
      _proposalID: PromiseOrValue<BytesLike>,
      _result: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    getDistributedKeyID(
      _proposalID: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getM(
      _proposalID: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getProposalID(
      _dao: PromiseOrValue<string>,
      _distributedKeyID: PromiseOrValue<BigNumberish>,
      _timestamp: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getR(
      _proposalID: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getRequest(
      _proposalID: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    submitRequestResult(
      _proposalID: PromiseOrValue<BytesLike>,
      _result: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}