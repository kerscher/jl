{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE LambdaCase #-}
-- |

module JL.Types where

import Control.Exception
import Data.Data
import qualified Data.HashMap.Strict as HM
import Data.HashMap.Strict (HashMap)
import Data.Scientific
import Data.Text (Text)
import Data.Vector (Vector)
import Text.Parsec.Error

data ParseException
  = TokenizerError !ParseError
  | ParserError !ParseError
 deriving (Typeable, Show)
instance Exception ParseException

-- | A type.
data Type
  = VariableType !TypeVariable
  | FunctionType !Type !Type
  | ValueType
  deriving (Ord, Eq, Show)

-- | A parsed expression.
data Expression
  = VariableExpression Variable
  | LambdaExpression Variable Expression
  | ApplicationExpression Expression Expression
  | InfixExpression Expression Variable Expression
  | IfExpression Expression Expression Expression
  | SubscriptExpression Subscripted [Subscript]
  | RecordExpression (HashMap Text Expression)
  | ArrayExpression (Vector Expression)
  | ConstantExpression Constant
  deriving (Show, Eq)

data Subscripted
  = WildcardSubscripted
  | ExpressionSubscripted Expression
  deriving (Show, Eq)

data Subscript
  = PropertySubscript Text
  | ExpressionSubscript Expression
  deriving (Show, Eq)

-- | Desugared core AST.
data Core
  = VariableCore Variable
  | LambdaCore Variable Core
  | ApplicationCore Core Core
  | IfCore Core Core Core
  | EvalCore (Core -> Core)
  | RecordCore (HashMap Text Core)
  | ArrayCore (Vector Core)
  | ConstantCore Constant

data Compare
  = ConstantCompare Constant
  | VectorCompare (Vector Compare)
  | RecordCompare [(Text, Compare)]
  deriving (Eq, Ord)

coreToCompare :: Core -> Compare
coreToCompare =
  \case
    ConstantCore c -> ConstantCompare c
    ArrayCore cs -> VectorCompare (fmap coreToCompare cs)
    RecordCore cs -> RecordCompare (HM.toList (fmap coreToCompare cs))
    _ -> error "Cannot compare that value for sorting"

-- | A self-evaluating constant.
data Constant
  = StringConstant Text
  | NumberConstant Scientific
  | BoolConstant Bool
  | NullConstant
  deriving (Show, Eq, Ord)

-- | A type variable, generated by the type system.
newtype TypeVariable =
  TypeVariable Int
  deriving (Show, Eq, Ord)

-- | A value variable, inputted by the programmer.
newtype Variable =
  Variable Text
  deriving (Show, Eq, Ord)

data Token
  = If
  | Then
  | Else
  | Case
  | Of
  | Backslash
  | RightArrow
  | Dollar
  | OpenParen
  | CloseParen
  | OpenBracket
  | CloseBracket
  | VariableToken !Text
  | StringToken !Text
  | Operator !Text
  | Period
  | Comma
  | Integer !Integer
  | Decimal !Double
  | OpenBrace
  | CloseBrace
  | Colon
  | NonIndentedNewline
  | Bar
  | TrueToken
  | FalseToken
  | NullToken
  deriving (Eq, Ord, Show)

data Location = Location
  { locationStartLine :: !Int
  , locationStartColumn :: !Int
  , locationEndLine :: !Int
  , locationEndColumn :: !Int
  } deriving (Show, Eq)

data Definition = Definition
  { definitionName :: Variable
  , definitionDoc :: Text
  , definitionType :: Type
  , definitionCore :: Core
  }
