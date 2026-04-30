import { render, screen, fireEvent, } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
const user = userEvent.setup();
import { Counter, reducer, initialState } from './../src/components/Counter';
import { renderHook, act } from '@testing-library/react'
import { useReducer } from 'react';
import { waitFor } from '@testing-library/react';

describe('Counter reducer', () => {
  it('renders correctly with initial state', () => {
    render(<Counter />);
    const countElement = screen.getByRole('heading');
    const increaseButton = screen.getByText(/increase/i);
    const decreaseButton = screen.getByText(/decrease/i);
    const resetButton = screen.getByText(/reset/i);
    const evalButton = screen.getByText(/eval/i);
    const input = screen.getByRole('textbox', {
      name: /textbox/i,
    });

    expect(countElement).toHaveTextContent('0');
    expect(increaseButton).toBeInTheDocument();
    expect(decreaseButton).toBeInTheDocument();
    expect(resetButton).toBeInTheDocument();
    expect(evalButton).toBeInTheDocument();
    expect(input).toBeInTheDocument();

  });

  it('should not change the state for unknown actions', () => {
    const action = { type: 'UNKNOWN_ACTION' };
    const currentState = { count: 3 };
    const result = reducer(currentState, action);
    expect(result).toEqual(currentState); // State should remain unchanged
  });

  it('should handle all action types correctly', async () => {
    // Spy on the reducer function
    const mockReducer = jest.fn(reducer);
    const { result } = renderHook(() => useReducer(mockReducer, initialState));
    let timesCalled = 0;

    // Initial state check
    expect(result.current[0]).toEqual(initialState);

    // Dispatch INCREASE action
    act(() => {
      result.current[1]({ type: 'INCREASE' });
    });

    // Check state after INCREASE
    expect(mockReducer).toHaveBeenCalledWith(initialState, { type: 'INCREASE' });
    expect(mockReducer).toHaveBeenCalledTimes(++timesCalled); //  + INCREASE
    expect(result.current[0]).toEqual({ count: 1 });

    // Dispatch DECREASE action
    act(() => {
      result.current[1]({ type: 'DECREASE' });
    });

    // Check state after DECREASE
    expect(mockReducer).toHaveBeenCalledWith({ count: 1 }, { type: 'DECREASE' });
    expect(mockReducer).toHaveBeenCalledTimes(++timesCalled); //  + INCREASE + DECREASE
    expect(result.current[0]).toEqual({ count: 0 }); // Should go to 0

    // Dispatch DECREASE action again (to test boundary)
    act(() => {
      result.current[1]({ type: 'DECREASE' });
    });

    // Check state after second DECREASE
    expect(mockReducer).toHaveBeenCalledWith({ count: 0 }, { type: 'DECREASE' });
    expect(mockReducer).toHaveBeenCalledTimes(++timesCalled); //  + INCREASE + DECREASE + DECREASE
    expect(result.current[0]).toEqual({ count: 0 }); // Should stay at 0

    // Dispatch INCREASE action again
    act(() => {
      result.current[1]({ type: 'INCREASE' });
    });

    // Check state after second INCREASE
    expect(mockReducer).toHaveBeenCalledWith({ count: 0 }, { type: 'INCREASE' });
    expect(mockReducer).toHaveBeenCalledTimes(++timesCalled); //  + INCREASE + DECREASE + DECREASE + INCREASE
    expect(result.current[0]).toEqual({ count: 1 }); // Should go back to 1

    // Dispatch RESET action
    act(() => {
      result.current[1]({ type: 'RESET' });
    });

    // Check state after RESET
    expect(mockReducer).toHaveBeenCalledWith({ count: 1 }, { type: 'RESET' });
    expect(mockReducer).toHaveBeenCalledTimes(++timesCalled); //  + INCREASE + DECREASE + DECREASE + INCREASE + RESET
    expect(result.current[0]).toEqual({ count: 0 }); // Should reset to 0
    // Dispatch INCREASE action
    act(() => {
      result.current[1]({ type: 'INCREASE' });
    });
    //another increase 
    expect(mockReducer).toHaveBeenCalledWith({ count: 0 }, { type: 'INCREASE' });
    expect(mockReducer).toHaveBeenCalledTimes(++timesCalled); //  + INCREASE + DECREASE + DECREASE + INCREASE + INCREASE
    expect(result.current[0]).toEqual({ count: 1 }); // Should go back to 1

    // Dispatch EVAL action
    act(() => {
      result.current[1]({ type: 'EVAL', payload: 'value * 2137' });
    });

    expect(mockReducer).toHaveBeenCalledWith({ count: 1 }, { type: 'EVAL', payload: 'value * 2137' });
    expect(mockReducer).toHaveBeenCalledTimes(++timesCalled); //  + INCREASE + DECREASE + DECREASE + INCREASE + INCREASE
    expect(result.current[0]).toEqual({ count: 2137 }); // Should go back to 1

    // Dispatch EVAL action
    act(() => {
      result.current[1]({ type: 'EVAL', payload: '' });
    });

    expect(mockReducer).toHaveBeenCalledWith({ count: 2137 }, { type: 'EVAL', payload: '' });
    expect(mockReducer).toHaveBeenCalledTimes(++timesCalled);
    expect(result.current[0]).toEqual({ count: 2137 });

    // Dispatch EVAL action
    act(() => {
      result.current[1]({ type: 'EVAL', payload: 'value * -1' });
    });

    expect(mockReducer).toHaveBeenCalledWith({ count: 2137 }, { type: 'EVAL', payload: 'value * -1' });
    expect(mockReducer).toHaveBeenCalledTimes(++timesCalled);
    expect(result.current[0]).toEqual({ count: 0 });

    // Dispatch EVAL action
    act(() => {
      result.current[1]({ type: 'EVAL', payload: 'value * value' });
    });

    expect(mockReducer).toHaveBeenCalledWith({ count: 0 }, { type: 'EVAL', payload: 'value * value' });
    expect(mockReducer).toHaveBeenCalledTimes(++timesCalled);
    expect(result.current[0]).toEqual({ count: 0 });

    // Dispatch INCREASE action again
    act(() => {
      result.current[1]({ type: 'INCREASE' });
    });

    expect(mockReducer).toHaveBeenCalledWith({ count: 0 }, { type: 'INCREASE' });
    expect(mockReducer).toHaveBeenCalledTimes(++timesCalled);

    expect(result.current[0]).toEqual({ count: 1 });
    act(() => {
      result.current[1]({ type: 'INCREASE' });
    });

    expect(mockReducer).toHaveBeenCalledWith({ count: 1 }, { type: 'INCREASE' });
    expect(mockReducer).toHaveBeenCalledTimes(++timesCalled);
    expect(result.current[0]).toEqual({ count: 2 });

    //get real close to Infinity
    let value = 2;
    for (let i = 0; i < 10; i++) {
      act(() => {
        result.current[1]({ type: 'EVAL', payload: 'value * value' });
      });

      expect(mockReducer).toHaveBeenCalledWith({ count: value }, { type: 'EVAL', payload: 'value * value' });
      expect(Number.isFinite(result.current[0].count)).toBe(true);
      expect(mockReducer).toHaveBeenCalledTimes(++timesCalled);

      value = value * value

    }
    //get real close to Infinity
    act(() => {
      result.current[1]({ type: 'EVAL', payload: 'value * value' });
    });

    expect(mockReducer).toHaveBeenCalledWith({ count: 0 }, { type: 'EVAL', payload: 'value * value' });
    expect(Number.isFinite(result.current[0].count)).toBe(true);
    expect(mockReducer).toHaveBeenCalledTimes(++timesCalled);

    value = value * value

  });

  it('evaluates expression from input', async () => {
    render(<Counter />);

    const input = screen.getByRole('textbox', { name: /textbox/i });

    const evalB = screen.getByText(/eval/i);
    const increaseB = screen.getByText(/increase/i);
    const decreaseB = screen.getByText(/decrease/i);
    const resetB = screen.getByText(/reset/i);
    await expectCountToBeAsyncRegex(0);

    await clickTimes(user, increaseB, 10);
    await expectCountToBeAsyncRegex(10);

    await clickTimes(user, decreaseB, 3);
    await expectCountToBeAsyncRegex(7);

    await clickTimes(user, resetB, 1);
    await expectCountToBeAsyncRegex(0);

    await clickTimes(user, increaseB, 7);
    await expectCountToBeAsyncRegex(7);
    //No payload, return same value
    await clickTimes(user, evalB, 1);
    await expectCountToBeAsyncRegex(7);
    //Change payload

    await userEvent.type(input, 'value * 2137');
    await clickTimes(user, evalB, 1);

    await expectCountToBeAsyncRegex(14959);

    //Change payload to trash
    await user.clear(input);
    await userEvent.type(input, 'asdf');
    await clickTimes(user, evalB, 1);

    await expectCountToBeAsyncRegex(14959);
    //Change payload to trash
    await user.clear(input);
    await userEvent.type(input, 'value * -1');
    await clickTimes(user, evalB, 1);

    await expectCountToBeAsyncRegex(0);
    await user.clear(input);

    await userEvent.type(input, 'value * value');
    await clickTimes(user, evalB, 10);
    await expectCountToBeAsyncRegex(0);


    await clickTimes(user, increaseB, 7);
    await expectCountToBeAsyncRegex(7);



    await user.clear(input);
    await userEvent.type(input, 'value * value');
    await clickTimes(user, evalB, 10);
    await expectCountToBeAsyncRegex(0);

  });

});
const clickTimes = async (user, element, times) => {
  for (let i = 0; i < times; i++) {
    await user.click(element);
  }
};


const expectCountToBeAsyncRegex = async (value) => {
  await waitFor(() => {
    expect(
      screen.getByRole('heading', { level: 1 })
    ).toHaveTextContent(new RegExp(`^${value}$`));
  });
};